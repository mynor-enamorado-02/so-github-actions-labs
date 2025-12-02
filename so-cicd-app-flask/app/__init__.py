from flask import Flask
import os

def create_app():
    app = Flask(__name__)
    
    # Configuración básica
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
    app.config['VERSION'] = os.environ.get('VERSION', '1.0.0')
    
    # Registrar blueprints/rutas
    from app import routes
    app.register_blueprint(routes.bp)
    
    return app
