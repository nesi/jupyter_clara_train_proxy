import os
import subprocess
import pkg_resources
from pathlib import Path

def setup_clara():
    home_path = Path(os.environ["HOME"])
    
    sif_path = "/opt/nesi/containers/clara/clara-train-sdk_v4.0.sif"
    aiaa_path = "/opt/nvidia/medical/aiaa/AIAA"
    icon_path = pkg_resources.resource_filename("jupyter_clara_train_proxy", "nvidia_logo.svg")
    wrapper_path = pkg_resources.resource_filename("jupyter_clara_train_proxy", "singularity_wrapper.sh")

    return {
        "command": [
            wrapper_path,
            "{port}",
            "{base_url}",
        ],
        "timeout": 60,
        "environment": {},
        "absolute_url": False,
        "launcher_entry": {
            "icon_path": icon_path,
            "title": "Clara Train",
        },
    }
