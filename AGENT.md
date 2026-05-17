# AGENT.md - Arquitectura y Flujo del Proyecto TFG

## Stack Tecnológico
- **Frontend**: Flutter (para la SuperApp O2O con billetera y Pasaporte Digital)
- **Backend**: Python/FastAPI vía LAIA (orquestación cognitiva)
- **Base de Datos**: MongoDB
- **Ontologías**: Jena (para gestión de conocimiento semántico)

## Reglas Generales
- Uso de Engram para memoria persistente y contextualización del agente.
- Integración con MCP (Model Context Protocol) para herramientas especializadas.
- Skills Registry para modularizar conocimientos y reglas específicas del dominio.

## Flujo de Trabajo
- Actuar siempre en "Plan Mode" antes de proponer cualquier código o cambio.
- Cargar las Skills necesarias según el contexto del task (ej. arquitectura O2O, Flutter UI, backend LAIA).
- Esperar aprobación explícita del usuario humano (Human in the Loop - HITL) antes de ejecutar cambios críticos.
- Mantener consistencia con la arquitectura moderna de orquestación.