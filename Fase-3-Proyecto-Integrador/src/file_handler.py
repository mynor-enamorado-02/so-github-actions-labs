import os
import json
from datetime import datetime
from utils.logger import setup_logger

logger = setup_logger()

class FileProcessor:
    def __init__(self, base_dir="."):
        self.base_dir = base_dir
        logger.info(f"FileProcessor inicializado en {os.path.abspath(base_dir)}")
    
    def create_sample_file(self, filename="sample_data.json"):
        """Crea un archivo de ejemplo"""
        data = {
            "timestamp": datetime.now().isoformat(),
            "system": os.name,
            "platform": os.uname().sysname if hasattr(os, 'uname') else "Unknown",
            "message": "Archivo creado por CI/CD Pipeline Project"
        }
        
        filepath = os.path.join(self.base_dir, filename)
        
        try:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
            logger.info(f"Archivo creado: {filepath}")
            return True
        except Exception as e:
            logger.error(f"Error al crear archivo: {e}")
            return False
    
    def list_files(self, directory="."):
        """Lista archivos en un directorio"""
        try:
            files = os.listdir(directory)
            logger.debug(f"Archivos en {directory}: {len(files)} encontrados")
            return files
        except Exception as e:
            logger.error(f"Error al listar archivos: {e}")
            return []
    
    def get_file_info(self, filename):
        """Obtiene información de un archivo"""
        try:
            stats = os.stat(filename)
            return {
                'size': stats.st_size,
                'modified': datetime.fromtimestamp(stats.st_mtime),
                'created': datetime.fromtimestamp(stats.st_ctime)
            }
        except Exception as e:
            logger.error(f"Error al obtener info del archivo: {e}")
            return None
