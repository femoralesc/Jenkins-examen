# Usamos Python slim para mantenerlo liviano
FROM python:3.11-slim

# Establecemos el directorio de trabajo
WORKDIR /app

# Copiamos el archivo de dependencias
COPY requirements.txt .

# Creamos un virtualenv y instalamos dependencias
RUN python -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# Copiamos el resto de la app
COPY . .

# Exponemos el puerto 5000
EXPOSE 5000

# Comando para correr la app
CMD ["/bin/bash", "-c", ". venv/bin/activate && python vulnerable_flask_app.py --host 0.0.0.0"]
