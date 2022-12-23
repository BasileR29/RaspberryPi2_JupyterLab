FROM balenalib/raspberry-pi2-debian-python:3.9.15-bullseye

WORKDIR /root

RUN apt-get update && \
    apt-get install -y libncurses5-dev libzmq3-dev libfreetype6-dev libpng-dev libffi-dev && \
    apt-get install -y python3-dev && \
    apt-get install -y patch build-essential


RUN pip3 install --upgrade --no-cache-dir pip && \
    pip3 config set global.extra-index-url https://www.piwheels.org/simple

RUN pip3 --no-cache-dir install cython && \
    pip3 --no-cache-dir install readline && \
    pip3 --no-cache-dir install ipywidgets && \
    pip3 --no-cache-dir install jupyter && \
    pip3 --no-cache-dir install jupyterlab

# Configure jupyter
RUN jupyter nbextension enable --py widgetsnbextension && \
    jupyter serverextension enable --py jupyterlab && \
    jupyter notebook --generate-config && \
    mkdir notebooks

RUN sed -i "/c.NotebookApp.open_browser/c c.NotebookApp.open_browser = False" /root/.jupyter/jupyter_notebook_config.py \
        && sed -i "/c.NotebookApp.ip/c c.NotebookApp.ip = '*'" /root/.jupyter/jupyter_notebook_config.py \
        && sed -i "/c.NotebookApp.notebook_dir/c c.NotebookApp.notebook_dir = '/root'" /root/.jupyter/jupyter_notebook_config.py

VOLUME /root/notebooks

# Add Tini. Tini operates as a process subreaper for jupyter. This prevents kernel crashes.
ENV TINI_VERSION 0.18.0
ENV CFLAGS="-DPR_SET_CHILD_SUBREAPER=36 -DPR_GET_CHILD_SUBREAPER=37"

ADD https://github.com/krallin/tini/archive/v${TINI_VERSION}.tar.gz /root/v${TINI_VERSION}.tar.gz
RUN apt-get install -y cmake && \
    tar zxvf v${TINI_VERSION}.tar.gz \
        && cd tini-${TINI_VERSION} \
        && cmake . \
        && make \
        && cp tini /usr/bin/. \
        && cd .. \
        && rm -rf "./tini-${TINI_VERSION}" \
        && rm "./v${TINI_VERSION}.tar.gz"


# Install usefull python packages for data scientists
#RUN apt-get install -y \
#        libhdf5-dev \
#        liblapack-dev \
#        gfortran
#RUN pip3 install requests numpy scipy scikit-learn nltk pandas seaborn tables matplotlib ipywidgets


ENTRYPOINT ["/usr/bin/tini", "--"]

EXPOSE 8888

CMD ["jupyter", "lab", "--allow-root"]
