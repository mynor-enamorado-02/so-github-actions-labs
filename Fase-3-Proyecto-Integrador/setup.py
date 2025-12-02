from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="fase-3-proyecto-integrador",
    version="0.1.0",
    author="Mynor Enamorado",
    description="Proyecto integrador CI/CD Pipeline Multi-Plataforma",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.8",
    install_requires=[],
    entry_points={
        "console_scripts": [
            "simpleapp=src.app:main",
        ],
    },
)
