from setuptools import setup, find_packages

setup(
    name="jupter-clara-train-proxy",
    version="0.2.0",
    packages=find_packages(),
    package_data={"jupyter_clara_train_proxy": ["nvidia_logo.svg", "singularity_wrapper.sh"]},
    entry_points={
        "jupyter_serverproxy_servers": ["clara = jupyter_clara_train_proxy:setup_clara"]
    }
)
