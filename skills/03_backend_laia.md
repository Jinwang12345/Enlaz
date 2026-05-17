# 03_backend_laia.md

Este skill especifica los esquemas YAML para FastAPI vía LAIA, incluyendo endpoints para la billetera, Pasaporte Digital, integración con MongoDB, y gestión de ontologías con Jena.

# Skill: Creación de Esquemas YAML para LAIA

## Contexto
LAIA es nuestro motor de generación de código. Lee archivos `.yaml` y genera automáticamente modelos de base de datos (MongoDB), controladores, servicios y rutas de FastAPI. Como activamos el soporte para Ontologías (Jena), nuestros modelos pueden incluir metadatos semánticos.

## Ubicación de los archivos
Todos los esquemas YAML deben crearse dentro de la carpeta del backend generada por LAIA, típicamente en `backend/domain/yaml/` (o el directorio que LAIA haya designado para los esquemas).

## Reglas de Sintaxis YAML de LAIA
1. Cada entidad debe ir en su propio archivo con la primera letra en mayúscula (ej: `User.yaml`, `Wallet.yaml`).
2. Los tipos de datos permitidos son: `string`, `integer`, `float`, `boolean`, `datetime`, `array`, `object`.
3. Para relaciones con otras colecciones de MongoDB, usar el tipo `objectId`.

## Plantilla Base Oficial
```yaml
class: NombreEntidad
properties:
  nombre_campo:
    type: string # Tipo de dato
    required: true # boolean
    unique: false # boolean
    default: "valor_por_defecto" # opcional
    ontology: "[http://schema.org/Propiedad](http://schema.org/Propiedad)" # Clave para el Pasaporte Digital (Jena)