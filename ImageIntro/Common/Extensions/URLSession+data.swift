import Foundation

extension URLSession {
    
    // MARK: - Получение "сырых" данных с проверкой ошибок
    func data(for request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let task = dataTask(with: request) { data, response, error in
            let fulfill: (Result<Data, Error>) -> Void = { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }

            if let data = data,
               let response = response as? HTTPURLResponse {
                if 200..<300 ~= response.statusCode {
                    fulfill(.success(data))
                } else {
                    print("❌ Неверный HTTP статус-код: \(response.statusCode)")
                    fulfill(.failure(NetworkError.httpStatusCode(response.statusCode)))
                }
            } else if let error = error {
                print("❌ Сетевая ошибка запроса: \(error.localizedDescription)")
                fulfill(.failure(NetworkError.urlRequestError(error)))
            } else {
                print("❌ Неизвестная ошибка URLSession")
                fulfill(.failure(NetworkError.urlSessionError))
            }
        }
        return task
    }

    // MARK: - Декодирование объекта из ответа (Generic)
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        
        return data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    print("[objectTask]: Ошибка декодирования — \(error.localizedDescription), данные: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(.failure(NetworkError.decodingError(error)))
                }

            case .failure(let error):
                print("[objectTask]: Ошибка получения данных — \(error)")
                completion(.failure(error))
            }
        }
    }
}
