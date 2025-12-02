import os
import time
from datetime import datetime
from utils.logger import setup_logger
from file_handler import FileProcessor

logger = setup_logger()

class SimpleApp:
    def __init__(self):
        self.file_processor = FileProcessor()
        logger.info("Aplicación iniciada")
    
    def run(self):
        """Método principal de la aplicación"""
        logger.info("Ejecutando aplicación")
        
        
        self.file_processor.create_sample_file()
        
      
        files = self.file_processor.list_files(".")
        logger.info(f"Archivos en directorio: {files}")
        
       
        result = self.perform_operation(10, 5)
        logger.info(f"Resultado de operación: {result}")
        
        return result
    
    def perform_operation(self, a, b):
        """Operación simple con prueba unitaria"""
        logger.debug(f"Realizando operación con {a} y {b}")
        return a + b * 2

def main():
    app = SimpleApp()
    return app.run()

if __name__ == "__main__":
    main()
