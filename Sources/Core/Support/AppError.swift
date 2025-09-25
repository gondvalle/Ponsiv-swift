import Foundation

public enum AppError: Error, LocalizedError, Sendable {
    case notFound
    case invalidCredentials
    case emailAlreadyUsed
    case decodingFailed
    case persistenceFailed
    case missingSession
    case missingUser
    case cancelled
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "El recurso solicitado no existe."
        case .invalidCredentials:
            return "Email o contraseña incorrectos."
        case .emailAlreadyUsed:
            return "Ese email ya está registrado."
        case .decodingFailed:
            return "No se pudo decodificar la respuesta."
        case .persistenceFailed:
            return "No se pudieron guardar los datos."
        case .missingSession:
            return "Debes iniciar sesión para continuar."
        case .missingUser:
            return "El usuario no está disponible."
        case .cancelled:
            return "La operación se canceló."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}
