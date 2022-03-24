FROM alpine:latest

RUN apk update
RUN apk add wget uuidgen jq bash
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc
RUN chmod +x mc
ADD run.sh .
RUN chmod +x run.sh
