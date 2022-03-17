FROM python:3
RUN pip install --upgrade pip
RUN pip install pytest pytest-cov
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
