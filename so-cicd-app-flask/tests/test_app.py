import pytest
import json
import sys
import os

# Agregar el directorio raíz al path para importar la aplicación
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from app import create_app

@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_route(client):
    """Test para la ruta principal"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Aplicación SO CI/CD' in response.data

def test_info_route(client):
    """Test para la ruta de información"""
    response = client.get('/info')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert 'sistema_operativo' in data
    assert 'python_version' in data
    assert 'entorno' in data
    assert 'version_app' in data
    assert 'variables_entorno' in data

def test_health_route(client):
    """Test para la ruta de verificación de salud"""
    response = client.get('/health')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'timestamp' in data
    assert 'service' in data

def test_environment_variables(client):
    """Test que verifica que las variables de entorno se muestren correctamente"""
    response = client.get('/info')
    data = json.loads(response.data)
    
    env_vars = data['variables_entorno']
    assert 'FLASK_ENV' in env_vars
    assert 'VERSION' in env_vars
    # NODE_ENV puede o no estar definido, pero debería estar en la respuesta
    assert 'NODE_ENV' in env_vars
