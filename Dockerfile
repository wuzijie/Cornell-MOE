# This is based upon http://phusion.github.io/baseimage-docker/ with some
# inspiration from https://github.com/phusion/passenger-docker
FROM ubuntu:14.04

# Configure a non-privileged user named app. It is highly suggested you do not
# run your application as root.
RUN addgroup --gid 9999 app &&\
    adduser --uid 9999 --gid 9999 --disabled-password --gecos "Application" app &&\
    usermod -L app

# BEGIN: Install system level dependencies for your application.
RUN apt-get update && apt-get install -y build-essential gcc

# Install software from Ubuntu.
RUN apt-get install -y nginx python python-dev python2.7 python2.7-dev

# Install pip and virtualenv systemwide for Python.
ADD https://raw.github.com/pypa/pip/master/contrib/get-pip.py /tmp/get-pip.py
RUN python /tmp/get-pip.py

# Install MOE system dependencies.
RUN apt-get install -y cmake libboost-all-dev doxygen libblas-dev liblapack-dev gfortran git make flex bison libssl-dev libedit-dev

# END: Install system level dependencies for your application.

# BEGIN: Build your application

# Upload the code set the right permissions.
ADD requirements.txt /home/app/MOE/
RUN cd /home/app/MOE/ && pip install -r requirements.txt

# Copy over the code
ADD . /home/app/MOE/
# Install the python
RUN export MOE_NO_BUILD=True
RUN cd /home/app/MOE && pip install -e . && python setup.py install
# Build the C++
RUN cd /home/app/MOE/moe && mkdir build
RUN cd /home/app/MOE/moe/build && cmake /home/app/MOE/moe/optimal_learning/cpp/
RUN cd /home/app/MOE/moe/build && make
# Copy the built C++ into the python
RUN cp -r /home/app/MOE/moe/build /usr/local/lib/python2.7/dist-packages/moe/.

RUN chown -R app:app /home/app/MOE && chmod -R a+r /home/app/MOE

# Run the installation as the app user.
USER app

# To run: cd /home/app/MOE && pserve --reload development.ini

# END: Build your application

# Configure docker container.
USER root
EXPOSE 22 80 443 6543
CMD ["/sbin/my_init"]
