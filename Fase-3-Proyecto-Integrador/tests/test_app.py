import unittest
import tempfile
import os
from src.app import SimpleApp
from src.file_handler import FileProcessor
from src.utils.logger import setup_logger

class TestSimpleApp(unittest.TestCase):
    def setUp(self):
        self.app = SimpleApp()
        self.temp_dir = tempfile.mkdtemp()
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_perform_operation(self):
        """Test de la operación principal"""
        result = self.app.perform_operation(10, 5)
        self.assertEqual(result, 20)  
    
    def test_perform_operation_with_negative(self):
        """Test con números negativos"""
        result = self.app.perform_operation(-5, 3)
        self.assertEqual(result, 1)  
    
    def test_app_initialization(self):
        """Test de inicialización de la app"""
        self.assertIsNotNone(self.app.file_processor)

class TestFileProcessor(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.processor = FileProcessor(self.temp_dir)
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_create_sample_file(self):
        """Test creación de archivo"""
        result = self.processor.create_sample_file("test.json")
        self.assertTrue(result)
        
        # Verificar que el archivo existe
        filepath = os.path.join(self.temp_dir, "test.json")
        self.assertTrue(os.path.exists(filepath))
    
    def test_list_files(self):
        """Test listado de archivos"""
        # Crear archivos de prueba
        test_files = ["test1.txt", "test2.txt", "test3.txt"]
        for file in test_files:
            with open(os.path.join(self.temp_dir, file), 'w') as f:
                f.write("test")
        
        files = self.processor.list_files(self.temp_dir)
        self.assertEqual(len(files), 3)
    
    def test_get_file_info(self):
        """Test obtención de información de archivo"""
        test_file = os.path.join(self.temp_dir, "info_test.txt")
        with open(test_file, 'w') as f:
            f.write("Test content")
        
        info = self.processor.get_file_info(test_file)
        self.assertIsNotNone(info)
        self.assertIn('size', info)

if __name__ == '__main__':
    unittest.main()
