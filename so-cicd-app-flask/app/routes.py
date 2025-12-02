from flask import Blueprint, render_template, jsonify, current_app
import os
import platform
import datetime

bp = Blueprint('routes', __name__)

@bp.route('/')
def index():
    """Página principal"""
    # Pasar las variables al template
    return render_template('index.html', 
                          env=os.environ.get('FLASK_ENV', 'development'),
                          version=current_app.config.get('VERSION', '1.0.0'))

@bp.route('/info')
def info():
    """Endpoint que muestra información del sistema"""
    system_info = {
        'sistema_operativo': platform.system(),
        'version_sistema': platform.release(),
        'python_version': platform.python_version(),
        'entorno': os.environ.get('FLASK_ENV', 'development'),
        'version_app': current_app.config.get('VERSION', '1.0.0'),
        'tiempo_servidor': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'variables_entorno': {
            'FLASK_ENV': os.environ.get('FLASK_ENV', 'No definido'),
            'NODE_ENV': os.environ.get('NODE_ENV', 'No definido'),
            'VERSION': os.environ.get('VERSION', 'No definido'),
            'RENDER': os.environ.get('RENDER', 'No definido'),
            'PYTHON_VERSION': os.environ.get('PYTHON_VERSION', 'No definido')
        }
    }
    return jsonify(system_info)

@bp.route('/health')
def health_check():
    """Endpoint de verificación de salud"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat(),
        'service': 'so-cicd-app-flask',
        'version': current_app.config.get('VERSION', '1.0.0')
    })
