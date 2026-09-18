ARG VIRTUAL_ENV=/app/.venv
FROM python:3.14 AS builder
ARG VIRTUAL_ENV
WORKDIR /app

RUN python -m venv .venv
COPY requirements.txt .
RUN .venv/bin/pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY gunicorn.conf.py .

# The "gunicorn" command is an executable script with a shebang to /app/.venv/bin/python, which itself is a symlink to
# /usr/local/bin/python (in the official python:... image). However, the Ubuntu chiseled image we use in "final" does
# not have the Python binary at /usr/local/bin/python but at /usr/bin/python3. We therefore remove the symlink
# and create a new one to the correct Python binary.
RUN rm .venv/bin/python && ln -s /usr/bin/python3 .venv/bin/python

# Whenever a new build of the ghcr.io/mshekow/python:3.14-chiseled image is available, a tool like Renovate Bot
# can update the sha256 digest
FROM ghcr.io/mshekow/python:3.14-chiseled@sha256:916be0dcaf66bb4aff792b1ae7dbdb67c3ec77b399d0c316260d77a0c7a63e1a AS final
ARG VIRTUAL_ENV
WORKDIR /app
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
COPY --from=builder /app /app
ENTRYPOINT ["gunicorn", "--config", "gunicorn.conf.py", "app:app"]
