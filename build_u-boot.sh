#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# --- Helper Functions ---

check_command() {
	command -v -- "$1" >/dev/null 2>&1
}

get_git_url() {
	local mirror_path="$1"
	local github_url="$2"
	if [ -f .gitlab-runner ]; then
		echo "https://forgejo.gfnd.rcn-ee.org:3000${mirror_path}"
	else
		echo "${github_url}"
	fi
}

report_and_compare() {
	local file_path="$1"
	local label="$2"
	local size_file=".last_build_sizes.txt"
	local summary_file=".build_summary.tmp"
	local new_sizes_file=".new_sizes.txt"

	if [ -f "$file_path" ]; then
		local current_bytes
		current_bytes=$(stat -c%s "$file_path" 2>/dev/null || echo 0)
		[ "$current_bytes" -eq 0 ] && return

		local current_kb=$((current_bytes / 1024))
		local diff_kb=0
		local diff_bytes=0
		local status="NEW"

		if [ -f "$size_file" ]; then
			local prev_bytes
			prev_bytes=$(grep "^${label}:" "$size_file" | cut -d':' -f2 || echo "$current_bytes")

			diff_bytes=$((current_bytes - prev_bytes))
			diff_kb=$((diff_bytes / 1024))

			if [ "$diff_bytes" -gt 0 ]; then status="INCREASED";
			elif [ "$diff_bytes" -lt 0 ]; then status="DECREASED";
			else status="UNCHANGED"; fi
		fi

		echo "[$status] $label: ${current_kb}KB"
		echo "${label}|${current_bytes}|${diff_bytes}|${diff_kb}|${status}" >> "$summary_file"
		echo "${label}:${current_bytes}" >> "$new_sizes_file"
	fi
}

log_sep() {
	echo "************************************************************************************"
}

# --- Compiler Detection ---

if check_command arm-linux-gnueabihf-gcc; then
	CC32="arm-linux-gnueabihf-"
elif check_command arm-linux-gnu-gcc; then
	CC32="arm-linux-gnu-"
else
	echo "Error: CC32 (arm-linux-gnueabihf-gcc or arm-linux-gnu-gcc) not found"
	exit 1
fi

CC64="aarch64-linux-gnu-"
if ! check_command "${CC64}gcc"; then
	echo "Error: CC64 (${CC64}gcc) not found"
	exit 1
fi

# --- Initialization ---

${CC32}gcc --version
${CC64}gcc --version

DIR="$PWD"
JOBS=$(nproc 2>/dev/null || echo 4)
. version.sh

if [ -f ".last_build_sizes.txt" ]; then
	echo "Cache restored: Found previous build sizes."
else
	echo "No cache found: This is likely a fresh build or cache was cleared."
	touch .last_build_sizes.txt
fi

log_sep
echo "[${UBOOT}:${TFA}:${OPTEE}:${TI_FIRMWARE}]"
log_sep

# --- Repository Cloning ---

# TI Firmware
if [ ! -d "./ti-linux-firmware/" ]; then
	URL=$(get_git_url "/TexasInstruments/ti-linux-firmware.git" "${TI_FIRMWARE_GIT}")
	echo "Cloning TI Firmware from: ${URL}"
	git clone -b "${TI_FIRMWARE}" "${URL}" --depth=1 ./ti-linux-firmware/
fi

# TFA
if [ ! -d "./trusted-firmware-a/" ]; then
	URL=$(get_git_url "/mirror/trusted-firmware-a.git" "${TFA_GIT}")
	echo "Cloning TFA from: ${URL}"
	git clone -b "${TFA}" "${URL}" --depth=1 ./trusted-firmware-a/
fi

# OP-TEE
if [ ! -d "./optee_os/" ]; then
	URL=$(get_git_url "/mirror/optee_os.git" "${OPTEE_GIT}")
	echo "Cloning OP-TEE from: ${URL}"
	git clone -b "${OPTEE}" "${URL}" --depth=1 ./optee_os/
fi

# U-Boot
if [ ! -d "./u-boot/" ]; then
	URL=$(get_git_url "/BeagleBoard.org/u-boot.git" "${UBOOT_GIT}")
	echo "Cloning U-Boot from: ${URL}"
	git clone -b "${UBOOT}" "${URL}" --depth=1 ./u-boot/
fi

log_sep
mkdir -p "${DIR}/public/"

# --- Build Configuration (Beagley-AI) ---

SOC_NAME="j722s"
SECURITY_TYPE="hs-fs"
SIGNED=""
TFA_BOARD="lite"
TFA_EXTRA_ARGS=""
OPTEE_PLATFORM="k3-am62x"
OPTEE_EXTRA_ARGS="CFG_WITH_SOFTWARE_PRNG=y"
UBOOT_CFG_CORTEXR="am67a_beagley_ai_r5_defconfig"
UBOOT_CFG_CORTEXA="am67a_beagley_ai_a53_defconfig"

# --- TFA Build ---

echo "Building TFA (Target Board: ${TFA_BOARD})..."
if ! make -C ./trusted-firmware-a/ -j"${JOBS}" \
	CROSS_COMPILE="${CC64}" \
	CFLAGS="" \
	LDFLAGS="" \
	ARCH=aarch64 \
	PLAT=k3 \
	SPD=opteed \
	TARGET_BOARD="${TFA_BOARD}" \
	${TFA_EXTRA_ARGS} all; then
	echo "Error: TFA build failed."
	ls -lha "${DIR}/trusted-firmware-a/"
	exit 2
fi

TFA_OUTPUT="./trusted-firmware-a/build/k3/${TFA_BOARD}/release/bl31.bin"

if [ -f "$TFA_OUTPUT" ]; then
	SIZE_KB=$(( $(stat -c%s "$TFA_OUTPUT") / 1024 ))
	echo "TFA Output found: $TFA_OUTPUT (${SIZE_KB} KB)"
	cp -v "$TFA_OUTPUT" "${DIR}/public/"
	report_and_compare "$TFA_OUTPUT" "TFA_BL31"
else
	echo "Error: bl31.bin not found after TFA build."
	exit 2
fi

rm -rf "${DIR}/trusted-firmware-a"

# --- OP-TEE Build ---

log_sep
echo "Building OP-TEE (Platform: ${OPTEE_PLATFORM})..."
if ! make -C ./optee_os/ -j"${JOBS}" \
	O=../optee \
	CROSS_COMPILE="${CC32}" \
	CROSS_COMPILE64="${CC64}" \
	CFLAGS="" \
	LDFLAGS="" \
	CFG_ARM64_core=y \
	PLATFORM="${OPTEE_PLATFORM}" \
	${OPTEE_EXTRA_ARGS} all; then
	echo "Error: OP-TEE build failed."
	exit 2
fi

TEE_PAGER="./optee/core/tee-pager_v2.bin"
if [ -f "$TEE_PAGER" ]; then
	SIZE_KB=$(( $(stat -c%s "$TEE_PAGER") / 1024 ))
	echo "OP-TEE Pager found: $TEE_PAGER (${SIZE_KB} KB)"
	cp -v "$TEE_PAGER" "${DIR}/public/"
	report_and_compare "$TEE_PAGER" "OPTEE_PAGER"
else
	echo "Error: tee-pager_v2.bin not found after OP-TEE build."
	exit 2
fi

rm -rf "${DIR}/optee/"

# --- U-Boot Cortex-R Build ---

build_label="Cortex-R"
build_dir="CORTEXR"

log_sep
echo "Building U-Boot ${build_label} ($UBOOT_CFG_CORTEXR)..."
make -C ./u-boot/ O=../${build_dir} CROSS_COMPILE="${CC32}" "${UBOOT_CFG_CORTEXR}"

if ! make -C ./u-boot/ -j"${JOBS}" O=../${build_dir} CROSS_COMPILE="${CC32}" BINMAN_INDIRS="${DIR}/ti-linux-firmware/"; then
	echo "Failure in u-boot ${build_label} build of [$UBOOT_CFG_CORTEXR]"
	ls -lha "${DIR}/${build_dir}/"
	exit 2
fi

TIBOOT3_BIN="${DIR}/${build_dir}/tiboot3-${SOC_NAME}-${SECURITY_TYPE}-evm.bin"
SYSFW_ITB="${DIR}/${build_dir}/sysfw-${SOC_NAME}-${SECURITY_TYPE}-evm.itb"

if [ -f "$TIBOOT3_BIN" ]; then
	echo "${build_label} Bin found: $TIBOOT3_BIN ($(( $(stat -c%s "$TIBOOT3_BIN") / 1024 )) KB)"
	cp -v "$TIBOOT3_BIN" "${DIR}/public/tiboot3.bin"
	report_and_compare "$TIBOOT3_BIN" "TIBOOT3_BIN"

	if [ -f "$SYSFW_ITB" ]; then
		echo "${build_label} ITB found: $SYSFW_ITB ($(( $(stat -c%s "$SYSFW_ITB") / 1024 )) KB)"
		cp -v "$SYSFW_ITB" "${DIR}/public/sysfw.itb"
		report_and_compare "$SYSFW_ITB" "SYSFW_ITB"
	fi
else
	echo "Error: Required ${build_label} binary $SYSFW_ITB not found."
	exit 2
fi

rm -rf "${DIR}/${build_dir}/"

# --- U-Boot Cortex-A Build ---

build_label="Cortex-A"
build_dir="CORTEXA"

if [ -f "${DIR}/public/bl31.bin" ] && [ -f "${DIR}/public/tee-pager_v2.bin" ]; then
	log_sep
	echo "Building U-Boot ${build_label} ($UBOOT_CFG_CORTEXA)..."

	make -C ./u-boot/ O=../${build_dir} CROSS_COMPILE="${CC64}" "${UBOOT_CFG_CORTEXA}"

	if ! make -C ./u-boot/ -j"${JOBS}" O=../${build_dir} CROSS_COMPILE="${CC64}" \
		BL31="${DIR}/public/bl31.bin" \
		TEE="${DIR}/public/tee-pager_v2.bin" \
		BINMAN_INDIRS="${DIR}/ti-linux-firmware/"; then
		echo "Error: U-Boot ${build_label} build failed."
		exit 2
	fi

	TISPL_BIN="${DIR}/${build_dir}/tispl.bin${SIGNED}"
	UBOOT_IMG="${DIR}/${build_dir}/u-boot.img${SIGNED}"

	if [ -f "$TISPL_BIN" ]; then
		cp -v "$TISPL_BIN" "${DIR}/public/tispl.bin" || true
		[ -f "$UBOOT_IMG" ] && cp -v "$UBOOT_IMG" "${DIR}/public/u-boot.img" || true

		report_and_compare "$TISPL_BIN" "TISPL_BIN"
		[ -f "$UBOOT_IMG" ] && report_and_compare "$UBOOT_IMG" "UBOOT_IMG"
	else
		echo "Failure in u-boot ${build_label} build of [$UBOOT_CFG_CORTEXA]"
		ls -lha "${DIR}/${build_dir}/"
		exit 2
	fi
	rm -rf "${DIR}/${build_dir}/"
else
	echo "Error: Missing required dependencies in public/ (bl31.bin or tee-pager_v2.bin)"
	exit 2
fi

rm -rf "${DIR}/${build_dir}/"

log_sep
echo "FINAL BUILD SIZE REPORT"
printf "%-15s | %-12s | %-12s | %-12s | %-10s\n" "COMPONENT" "SIZE (KB)" "DIFF (KB)" "DIFF (B)" "STATUS"
echo "------------------------------------------------------------------------------------"

if [ -f ".build_summary.tmp" ]; then
	while IFS='|' read -r label current_bytes diff_bytes diff_kb status; do
		# Convert current_bytes to KB for the table
		current_kb=$((current_bytes / 1024))

		# Format the diff string to show +/-
		if [ "$diff_bytes" -gt 0 ]; then
			diff_str_kb="+${diff_kb}KB"
			diff_str_b="+${diff_bytes}B"
		elif [ "$diff_bytes" -lt 0 ]; then
			# Use absolute value for display
			abs_diff_kb=$(( (diff_kb * -1) ))
			abs_diff_b=$(( (diff_bytes * -1) ))
			diff_str_kb="-${abs_diff_kb}KB"
			diff_str_b="-${abs_diff_b}B"
		else
			diff_str_kb="0KB"
			diff_str_b="0B"
		fi

		printf "%-15s | %-12s | %-12s | %-12s | %-10s\n" \
			"$label" "$current_kb" "$diff_str_kb" "$diff_str_b" "$status"
	done < ".build_summary.tmp"

	rm ".build_summary.tmp"
else
	echo "No summary data available."
fi
log_sep

# Finalize sizes
if [ -f ".new_sizes.txt" ]; then
	mv .new_sizes.txt .last_build_sizes.txt
fi

echo "Build Process Completed Successfully."
