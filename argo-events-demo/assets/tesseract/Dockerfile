FROM ubuntu:20.04

RUN apt update
RUN apt -y install software-properties-common dirmngr apt-transport-https lsb-release ca-certificates
RUN add-apt-repository -y ppa:alex-p/tesseract-ocr-devel
RUN apt-get update
RUN apt-get install -y tesseract-ocr python3.8 python3-pip libgl1 wget vim
RUN pip3 install opencv-python
RUN pip3 install pillow
RUN pip3 install pytesseract
RUN pip3 install redis
RUN pip3 install minio

ADD analyse.py .
