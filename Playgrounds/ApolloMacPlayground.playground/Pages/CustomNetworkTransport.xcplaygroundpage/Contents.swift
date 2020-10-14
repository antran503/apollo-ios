//: [Previous](@previous)

import Foundation
import StarWarsAPI
import Apollo
import PlaygroundSupport

class CustomNetworkTransport: NetworkTransport, RawNetworkFetcher {
    
    enum NetworkError: Error {
        case noDataAndNoError
    }
    
    let store: ApolloStore
    let requestBodyCreator: RequestBodyCreator
    
    var activeTaskHelpers = [RawDataCacheHelper]()
    
    init(store: ApolloStore,
         requestBodyCreator: RequestBodyCreator = ApolloRequestBodyCreator()) {
        self.store = store
        self.requestBodyCreator = requestBodyCreator
    }
    
    func remove(cacheHelper: RawDataCacheHelper) {
        guard let index = self.activeTaskHelpers.index(of: cacheHelper) else {
            return
        }
        
        self.activeTaskHelpers.remove(at: index)
    }
    
    func send<Operation: GraphQLOperation>(operation: Operation,
                                           cachePolicy: CachePolicy,
                                           contextIdentifier: UUID? = nil,
                                           callbackQueue: DispatchQueue = .main,
                                           completionHandler: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) -> Cancellable {
        let dataHelper = RawDataCacheHelper()
        dataHelper.sendViaCache(
            operation: operation,
            cachePolicy: cachePolicy,
            contextIdentifier: contextIdentifier,
            store: self.store,
            networkFetcher: self,
            completion: { result in
                self.remove(cacheHelper: dataHelper)
                callbackQueue.async {
                    completionHandler(result)
                }
            })
        self.activeTaskHelpers.append(dataHelper)
        return dataHelper
    }
    
    func fetchData<Operation: GraphQLOperation>(operation: Operation, completion: @escaping (Result<Data, Error>) -> Void) {
        self.createURL { url in
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let requestBody = self.requestBodyCreator.requestBody(for: operation)
            do {
                request.httpBody = try JSONSerializationFormat.serialize(value: requestBody)
            } catch {
                completion(.failure(error))
                return
            }

            URLSession.shared.dataTask(with: request, completionHandler: { data, _, error in
                if let networkError = error {
                    completion(.failure(networkError))
                    return
                }
                
                if let networkData = data {
                    completion(.success(networkData))
                    return
                }
                
                completion(.failure(NetworkError.noDataAndNoError))
            }).resume()
        }
    }
    
    private func createURL(completion: @escaping (URL) -> Void) {
        let string = "http://localhost:8080/graphql"
        let url = URL(string: string)!
        completion(url)
    }
}

let store = ApolloStore()
let networkTransport = CustomNetworkTransport(store: store)
let client = ApolloClient(networkTransport: networkTransport, store: store)

let query = HeroDetailsQuery(episode: .newhope)

client.fetch(query: query) { result in
    switch result {
    case .failure(let error):
        print("Error: \(error)")
    case .success(let graphqlResult):
        print("name: \(graphqlResult.data?.hero?.name ?? "NO NAME")")
    }
    
    PlaygroundPage.current.finishExecution()
}
PlaygroundPage.current.needsIndefiniteExecution = true

//: [Next](@next)
