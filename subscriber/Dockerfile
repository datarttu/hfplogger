FROM frolvlad/alpine-python3
WORKDIR /usr/src/app
COPY requirements.txt ./
RUN pip install --upgrade pip && \
    pip install -r requirements.txt
COPY hfp ./hfp/
COPY subscribe.py ./
RUN mkdir data
VOLUME ./data
CMD ["python", "./subscribe.py"]
