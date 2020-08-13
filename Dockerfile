
ARG AIRFLOW_VERSION="1.10.11"
ARG AIRFLOW_EXTRAS="all"
ARG ADDITIONAL_AIRFLOW_EXTRAS=""
ARG ADDITIONAL_PYTHON_DEPS=""

ARG AIRFLOW_HOME=/opt/airflow
ARG AIRFLOW_UID="50000"
ARG AIRFLOW_GID="50000"

ARG CASS_DRIVER_BUILD_CONCURRENCY="8"

ARG PYTHON_BASE_IMAGE="python:3.6-slim-buster"
ARG PYTHON_MAJOR_MINOR_VERSION="3.6"

FROM ${PYTHON_BASE_IMAGE}
SHELL ["/bin/bash", "-o", "pipefail", "-e", "-u", "-x", "-c"]

ENV ADDITIONAL_PYTHON_DEPS=${ADDITIONAL_PYTHON_DEPS}
ARG PYTHON_MAJOR_MINOR_VERSION
ENV PYTHON_MAJOR_MINOR_VERSION=${PYTHON_MAJOR_MINOR_VERSION}

# Make sure noninteractive debian install is used and language variables set
ENV DEBIAN_FRONTEND=noninteractive LANGUAGE=C.UTF-8 LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8 LC_MESSAGES=C.UTF-8

# Install curl and gnupg2 - needed to download nodejs in the next step
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
           curl \
           gnupg2 \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG ADDITIONAL_DEPS="libmariadb-dev libmariadb-dev-compat mariadb-client \
	gcc libsasl2-dev libkrb5-dev g++ dumb-init"
ENV ADDITIONAL_DEPS=${ADDITIONAL_DEPS}

# Install basic and additional apt dependencies
RUN mkdir -pv /usr/share/man/man1 \
    && mkdir -pv /usr/share/man/man7 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
           apt-transport-https \
           apt-utils \
           build-essential \
           ca-certificates \
           curl \
           gnupg \
           dirmngr \
           freetds-bin \
           freetds-dev \
           gosu \
           krb5-user \
           ldap-utils \
           libffi-dev \
           libkrb5-dev \
           libpq-dev \
           libsasl2-2 \
           libsasl2-dev \
           libsasl2-modules \
           libssl-dev \
           locales  \
           lsb-release \
           netcat \
           openssh-client \
           postgresql-client \
           python-selinux \
           sasl2-bin \
           software-properties-common \
           sqlite3 \
           sudo \
           unixodbc \
           unixodbc-dev \
           yarn \
           ${ADDITIONAL_DEPS} \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG AIRFLOW_EXTRAS
ENV AIRFLOW_EXTRAS=${AIRFLOW_EXTRAS}
ARG AIRFLOW_VERSION
ENV AIRFLOW_VERSION=${AIRFLOW_VERSION}

ENV PATH=${PATH}:/root/.local/bin

RUN pip install "apache-airflow[${AIRFLOW_EXTRAS}]==${AIRFLOW_VERSION}" \
    --use-feature=2020-resolver && \
    if [ -n "${ADDITIONAL_PYTHON_DEPS}" ]; \
    then pip install ${ADDITIONAL_PYTHON_DEPS}; fi
    
LABEL org.apache.airflow.distro="debian"
LABEL org.apache.airflow.distro.version="buster"
LABEL org.apache.airflow.module="airflow"
LABEL org.apache.airflow.component="airflow"
LABEL org.apache.airflow.image="airflow"
LABEL org.apache.airflow.uid="${AIRFLOW_UID}"
LABEL org.apache.airflow.gid="${AIRFLOW_GID}"

ENV DEBIAN_FRONTEND=noninteractive LANGUAGE=C.UTF-8 LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8 LC_MESSAGES=C.UTF-8

ARG AIRFLOW_UID
ENV AIRFLOW_UID=${AIRFLOW_UID}
ARG AIRFLOW_GID
ENV AIRFLOW_GID=${AIRFLOW_GID}
ARG AIRFLOW_HOME
ENV AIRFLOW_HOME=${AIRFLOW_HOME}
RUN addgroup --gid "${AIRFLOW_GID}" "airflow" && \
    adduser --quiet "airflow" --uid "${AIRFLOW_UID}" \
        --gid "${AIRFLOW_GID}" \
        --home "${AIRFLOW_HOME}"

ARG AIRFLOW_HOME
ENV AIRFLOW_HOME=${AIRFLOW_HOME}
RUN mkdir -pv "${AIRFLOW_HOME}"; \
    mkdir -pv "${AIRFLOW_HOME}/dags"; \
    mkdir -pv "${AIRFLOW_HOME}/logs"; \
    chown -R "airflow:root" "${AIRFLOW_HOME}"; \
    find "${AIRFLOW_HOME}" -executable -print0 | xargs --null chmod g+x && \
        find "${AIRFLOW_HOME}" -print0 | xargs --null chmod g+rw

COPY entrypoint.sh /entrypoint
COPY clean-logs.sh /clean-logs

RUN chmod a+x /entrypoint /clean-logs

RUN chmod g=u /etc/passwd

ENV GUNICORN_CMD_ARGS="--worker-tmp-dir /dev/shm"

WORKDIR ${AIRFLOW_HOME}

EXPOSE 8080 8793 5555

USER ${AIRFLOW_UID}

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint"]
CMD ["airflow", "--help"]
