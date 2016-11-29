FROM ubuntu:16.04
MAINTAINER Fernando, fernando.meyer@helmholtz-hzi.de

ENV PACKAGES make g++ wget unzip ca-certificates xz-utils bzip2 bc
RUN apt-get update -y && apt-get install -y --no-install-recommends ${PACKAGES}

ENV ASSEMBLER_DIR /tmp/assembler
ENV ASSEMBLER_URL https://github.com/jjcook/velour/archive
ENV ASSEMBLER_ZIP master.zip
ENV ASSEMBLER_BLD ls velour_minikmer_ptables*.tar.bz2 | xargs -n 1 tar xjvf && make 'MAXKMERLENGTH=63'
ENV ASSEMBLER_MV mv velour /usr/local/bin/ && mv minikmer_ptables /usr/local/bin/ && rm -r ${ASSEMBLER_DIR}
ENV VELOUR_DIR velour-master

RUN mkdir ${ASSEMBLER_DIR}
RUN cd ${ASSEMBLER_DIR} &&\
    wget --quiet --no-check-certificate ${ASSEMBLER_URL}/${ASSEMBLER_ZIP} &&\
    unzip ${ASSEMBLER_ZIP} &&\
    cd ${VELOUR_DIR} &&\
    eval ${ASSEMBLER_BLD} &&\
    eval ${ASSEMBLER_MV}

# Locations for biobox file validator
ENV VALIDATOR /bbx/validator/
ENV BASE_URL https://s3-us-west-1.amazonaws.com/bioboxes-tools/validate-biobox-file
ENV VERSION  0.x.y
RUN mkdir -p ${VALIDATOR}

# download the validate-biobox-file binary and extract it to the directory $VALIDATOR
RUN wget \
      --quiet \
      --output-document -\
      ${BASE_URL}/${VERSION}/validate-biobox-file.tar.xz \
    | tar xJf - \
      --directory ${VALIDATOR} \
      --strip-components=1

ENV PATH ${PATH}:${VALIDATOR}

# download the assembler schema
RUN wget \
    --output-document /schema.yaml \
    https://raw.githubusercontent.com/bioboxes/rfc/master/container/short-read-assembler/input_schema.yaml

ENV CONVERT https://github.com/bronze1man/yaml2json/raw/master/builds/linux_386/yaml2json
# download yaml2json and make it executable
RUN cd /usr/local/bin && wget --quiet ${CONVERT} && chmod 700 yaml2json

ENV JQ http://stedolan.github.io/jq/download/linux64/jq
# download jq and make it executable
RUN cd /usr/local/bin && wget --quiet ${JQ} && chmod 700 jq

# Add Taskfile to /
ADD Taskfile /

# Add assemble script to the directory /usr/local/bin inside the container.
# /usr/local/bin is appended to the $PATH variable what means that every script
# in that directory will be executed in the shell  without providing the path.
ADD assemble /usr/local/bin/

# These replace scripts originally shipped with Velour
ADD assemble_modified.sh /usr/local/bin/
ADD covcutoff_modified.sh /usr/local/bin/

ENTRYPOINT ["assemble"]
