# 02_frontend_flutter.md

Este skill contiene directrices para el desarrollo del frontend en Flutter, incluyendo patrones de UI/UX, gestión de rutas, integración con billetera digital, y mejores prácticas para la SuperApp O2O.

# Skill: Desarrollo Frontend con Flutter para TFG

## Contexto
El frontend se llama `eco_frontend` y debe comunicarse con el backend de LAIA (FastAPI) que corre en `http://localhost:8005`. 

## Configuración del Entorno
- **SDK Path**: `D:\EA\Flutter\flutter` (Configurado en settings.json).
- **Gestión de Estado**: Preferiblemente usar `Provider` o `Bloc` para mantener el código organizado.
- **Arquitectura**: Clean Architecture (Capa de Data, Domain y UI).

## Reglas de Conexión al Backend
1. **Modelos**: Cada entidad de LAIA (User, Wallet) debe tener su clase `Model` en Flutter con métodos `fromJson` y `toJson`.
2. **Servicio API**: Crear un `ApiService` centralizado usando el paquete `http` o `dio`.
3. **Manejo de Errores**: Siempre implementar try-catch en las peticiones de red para informar al usuario si el backend está caído.

## Estilo Visual
- Usar **Material 3**.
- Mantener un diseño "Eco-friendly" (tonos verdes, limpios y modernos).
- La App debe ser responsiva.

## Instrucciones para la IA (Tú)
Cuando el Arquitecto te pida una nueva pantalla o funcionalidad:
1. Revisa primero los archivos `.yaml` del backend para asegurar que los campos coinciden.
2. Genera primero el modelo de datos, luego el servicio y finalmente la interfaz (UI).
3. Si vas a añadir una dependencia nueva, indícale al usuario que debe ejecutar `flutter pub get`.