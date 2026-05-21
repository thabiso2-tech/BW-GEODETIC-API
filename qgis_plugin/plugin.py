# -*- coding: utf-8 -*-
"""
Botswana Geodetic Suite QGIS Plugin
Integrates geodetic calculations with QGIS
"""

from qgis.PyQt.QtWidgets import (
    QAction, QDialog, QVBoxLayout, QHBoxLayout,
    QLabel, QLineEdit, QPushButton, QComboBox,
    QTableWidget, QTableWidgetItem, QMessageBox
)
from qgis.PyQt.QtGui import QIcon
from qgis.core import QgsProject, QgsPointXY
import requests
import json

class BotswanaGeodeticPlugin:
    """Main QGIS plugin class"""
    
    def __init__(self, iface):
        self.iface = iface
        self.actions = []
        self.menu = "Botswana Geodetic"
        self.api_url = "http://localhost:8000"
        
    def initGui(self):
        """Create menu items and toolbar buttons"""
        # Transform coordinates action
        icon_path = ":/plugins/bw_geodetic/icon.svg"
        self.transform_action = QAction(
            QIcon(icon_path),
            "Transform Coordinates",
            self.iface.mainWindow()
        )
        self.transform_action.triggered.connect(self.show_transform_dialog)
        self.iface.addPluginToMenu(self.menu, self.transform_action)
        self.iface.addToolBarIcon(self.transform_action)
        
    def unload(self):
        """Clean up when plugin is disabled"""
        for action in self.actions:
            self.iface.removePluginMenu(self.menu, action)
            self.iface.removeToolBarIcon(action)
            
    def show_transform_dialog(self):
        """Show coordinate transformation dialog"""
        dialog = TransformDialog(self.iface, self.api_url)
        dialog.exec()

class TransformDialog(QDialog):
    """Dialog for coordinate transformation"""
    
    def __init__(self, iface, api_url):
        super().__init__()
        self.iface = iface
        self.api_url = api_url
        self.setup_ui()
        
    def setup_ui(self):
        """Create dialog UI"""
        self.setWindowTitle("Coordinate Transformation")
        self.setGeometry(100, 100, 600, 400)
        
        layout = QVBoxLayout()
        
        # Input fields
        input_layout = QHBoxLayout()
        
        input_layout.addWidget(QLabel("Latitude:"))
        self.lat_input = QLineEdit()
        self.lat_input.setPlaceholderText("e.g., 25.2608")
        input_layout.addWidget(self.lat_input)
        
        input_layout.addWidget(QLabel("Longitude:"))
        self.lon_input = QLineEdit()
        self.lon_input.setPlaceholderText("e.g., 25.9165")
        input_layout.addWidget(self.lon_input)
        
        layout.addLayout(input_layout)
        
        # CRS selection
        crs_layout = QHBoxLayout()
        
        crs_layout.addWidget(QLabel("Source CRS:"))
        self.source_crs = QComboBox()
        self.source_crs.addItems([
            "EPSG:4326 (WGS 84)",
            "EPSG:3857 (Web Mercator)",
            "EPSG:32635 (UTM Zone 35S)"
        ])
        crs_layout.addWidget(self.source_crs)
        
        crs_layout.addWidget(QLabel("Target CRS:"))
        self.target_crs = QComboBox()
        self.target_crs.addItems([
            "EPSG:4326 (WGS 84)",
            "EPSG:3857 (Web Mercator)",
            "EPSG:32635 (UTM Zone 35S)"
        ])
        self.target_crs.setCurrentIndex(1)
        crs_layout.addWidget(self.target_crs)
        
        layout.addLayout(crs_layout)
        
        # Transform button
        self.transform_btn = QPushButton("Transform")
        self.transform_btn.clicked.connect(self.transform_coordinates)
        layout.addWidget(self.transform_btn)
        
        # Results table
        self.results_table = QTableWidget()
        self.results_table.setColumnCount(4)
        self.results_table.setHorizontalHeaderLabels([
            "Original Lat", "Original Lon", "Transformed Lat", "Transformed Lon"
        ])
        layout.addWidget(self.results_table)
        
        # Add to map button
        self.add_to_map_btn = QPushButton("Add to Map as Point")
        self.add_to_map_btn.clicked.connect(self.add_to_map)
        layout.addWidget(self.add_to_map_btn)
        
        self.setLayout(layout)
        
    def transform_coordinates(self):
        """Call API to transform coordinates"""
        try:
            lat = float(self.lat_input.text())
            lon = float(self.lon_input.text())
            source_crs = self.source_crs.currentText().split()[0]
            target_crs = self.target_crs.currentText().split()[0]
            
            payload = {
                "latitude": lat,
                "longitude": lon,
                "source_crs": source_crs,
                "target_crs": target_crs
            }
            
            response = requests.post(
                f"{self.api_url}/api/v1/transform",
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            
            result = response.json()
            self.display_results(result)
            QMessageBox.information(self, "Success", "Transformation completed!")
            
        except ValueError:
            QMessageBox.warning(self, "Error", "Please enter valid latitude and longitude")
        except requests.RequestException as e:
            QMessageBox.critical(self, "API Error", f"Could not connect to API: {str(e)}")
            
    def display_results(self, result):
        """Display transformation results in table"""
        self.results_table.setRowCount(1)
        
        original = result["original"]
        transformed = result["transformed"]
        
        self.results_table.setItem(0, 0, QTableWidgetItem(f"{original['latitude']:.6f}"))
        self.results_table.setItem(0, 1, QTableWidgetItem(f"{original['longitude']:.6f}"))
        self.results_table.setItem(0, 2, QTableWidgetItem(f"{transformed['latitude']:.6f}"))
        self.results_table.setItem(0, 3, QTableWidgetItem(f"{transformed['longitude']:.6f}"))
        
        self.last_result = result
        
    def add_to_map(self):
        """Add transformed point to QGIS map"""
        if not hasattr(self, 'last_result'):
            QMessageBox.warning(self, "Error", "Please transform coordinates first")
            return
            
        result = self.last_result
        transformed = result["transformed"]
        
        point = QgsPointXY(transformed["longitude"], transformed["latitude"])
        
        # Add point marker to map
        from qgis.core import QgsVectorLayer, QgsFeature, QgsGeometry
        
        layer = QgsVectorLayer(f"Point?crs=EPSG:4326", "Transformed Points", "memory")
        pr = layer.dataProvider()
        
        feature = QgsFeature()
        feature.setGeometry(QgsGeometry.fromPointXY(point))
        pr.addFeatures([feature])
        
        QgsProject.instance().addMapLayer(layer)
        self.iface.mapCanvas().refresh()
        
        QMessageBox.information(self, "Success", "Point added to map!")

def classFactory(iface):
    """Factory function required by QGIS"""
    return BotswanaGeodeticPlugin(iface)
