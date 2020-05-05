FROM python:3.6-slim
COPY ./hello-ml.py /deploy/
COPY ./requirements.txt /deploy/
WORKDIR /deploy/
RUN pip install -r requirements.txt
EXPOSE 80
ENTRYPOINT ["python", "hello-ml.py"]
