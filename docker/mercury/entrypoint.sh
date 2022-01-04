#!/bin/sh

until cd /app/mercury
do
    echo "Waiting for server volume..."
done

until python manage.py migrate
do
    echo "Waiting for db to be ready..."
    sleep 2
done

# path with jupyter
export PATH="$HOME/.local/bin:$PATH"

echo "Add requirements for notebooks"
REQ=/app/notebooks/requirements.txt
if test -f "$REQ"; then
    pip install -r $REQ
fi

echo "Add notebooks"
for filepath in /app/notebooks/*.ipynb; do
    python manage.py add_notebook $filepath
done

DEBUG=False python manage.py collectstatic --noinput

DEBUG=False celery -A server worker --loglevel=error -P gevent --concurrency 4 -E &

DEBUG=False gunicorn server.wsgi --bind 0.0.0.0:8000 --workers 4 --threads 4

# for debug
# python manage.py runserver 0.0.0.0:8000