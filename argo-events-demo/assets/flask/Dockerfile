FROM python:3.9-bullseye

RUN pip3 install flask
ADD app.py .
ADD static ./static
ADD templates ./templates
RUN pip3 install pyopenssl

ENTRYPOINT [ "python" ]

CMD [ "app.py" ]
