#!/bin/python3

import argparse
import hashlib
import json
from pathlib import Path

DEST = "public/"
BOOTFS_FNAME = "bootfs.tar.xz"
BOOTFS = Path(f"{DEST}/{BOOTFS_FNAME}")


def get_file_sha256(file_path: Path) -> str:
    # Open the file in binary read mode ('rb')
    with open(file_path, "rb") as f:
        # Generate the file digest using SHA-256
        digest = hashlib.file_digest(f, "sha256")
    return digest.hexdigest()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("tag", help="Release tag", type=str)
    args = parser.parse_args()

    bootfs_url = f"https://github.com/beagleboard/u-boot-beagley-ai/releases/download/{args.tag}/{BOOTFS_FNAME}"

    with open(f"{DEST}/os_list.json", "w") as fp:
        json.dump(
            {
                "imager": {
                    "devices": [
                        {
                            "name": "BeagleY-AI",
                            "tags": [],
                            "description": "BeagleY-AI based on TI AM67A",
                            "flasher": "SdCard",
                            "bootfs": {
                                "url": bootfs_url,
                                "image_download_sha256": get_file_sha256(BOOTFS),
                                "image_download_size": BOOTFS.stat().st_size,
                            },
                        }
                    ]
                },
                "os_list": [],
            },
            fp,
        )
