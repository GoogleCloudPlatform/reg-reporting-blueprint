
import setuptools

# NOTE - these are not used in the custom
#        container currently.
#
#        Ideally, a requirements.txt would be used.
import setuptools as setuptools

setuptools.setup(
    install_requires=[
        'gcsfs==0.7.1', 
        'pandas_gbq==0.15.0',
        'numpy==1.21.6',
        'tensorboard==2.8.0',
        'tensorflow==2.9.1',
        'tensorflow-io==0.26.0',
    ],
    packages=setuptools.find_packages()
)

