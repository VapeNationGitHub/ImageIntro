import Foundation

extension URLSession {
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
}
