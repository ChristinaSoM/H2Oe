////
////  NetworkingService.swift
////  Login Screen Exercise
////
////  Created by Christina Moser on 16.10.25.
////
//
//import Foundation
//
//class NetworkingService: ObservableObject {
//    let session = URLSession(configuration: .default)
//    
//    // @escaping when require to escape the execution of the closure
//    func login(email: String, password: String, _ completionHandler: @escaping @Sendable (User?, NetworkingError?) -> Void) {
//        
//        let completeOnMain: @Sendable (User?, NetworkingError?) -> Void = { user, error in
//            DispatchQueue.main.async { completionHandler(user, error) }
//        }
//        
//        guard let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyCTryhlVmmRHYE7iQT3k0eeNRHIKsTMpRw") else {
//            print("Invalid URL")
//            return completeOnMain(nil, .unexpectedError)
//        }
//        
//        // Create a URLRequest for the POST request.
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // To get an appropriately formatted JSON string, you need to construct a dictionary of type [String: Any]
//        let body: [String: Any] = [
//            "email": email,
//            "password": password,
//            "returnSecureToken": true
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
//        } catch {
//            print("Body encoding error: \(error.localizedDescription)")
//            return completeOnMain(nil, .dictionarySerializationError)
//        }
//        
//        let task = session.dataTask(with: request) { data, response, error in
//            print("Response \(String(describing: response))")
//            print("Error: \(String(describing: error))")
//            
//            if let error = error as NSError? {
//                print("URLSession Error: \(error.localizedDescription)")
//                if error.code == NSURLErrorNotConnectedToInternet, error.domain == NSURLErrorDomain {
//                    return completeOnMain(nil, .networkOfflineError)
//                } else {
//                    return completeOnMain(nil, .unexpectedError)
//                }
//            }
//            
//            // HTTPURLResponse provides methods for accessing information specific to HTTP protocol responses ... like .statusCode and .allHeaderFields
//            guard let httpResponse = response as? HTTPURLResponse else {
//                return completeOnMain(nil, .unexpectedResponseFormatError)
//            }
//            
//            // print("Status: \(httpResponse.statusCode)")
//            // print("Response: \(httpResponse.allHeaderFields) \n")
//            
//            guard let data = data else {
//                return completeOnMain(nil, .unexpectedResponseFormatError)
//            }
//            
//            // print("Data: \(String(data: data, encoding: .utf8) ?? "<non-utf8>")")
//            
//            if (200...299).contains(httpResponse.statusCode) {
//                do {
//                    let user = try JSONDecoder().decode(User.self, from: data)
//                    print("User: \(user)")
//                    return completeOnMain(user, nil)
//                } catch {
//                    print("Response decoding error: \(error.localizedDescription)")
//                    return completeOnMain(nil, .unexpectedResponseFormatError)
//                }
//            }
//            
//            if let firebaseResponseError = try? JSONDecoder().decode(LoginErrorResponse.self, from: data) {
//                switch firebaseResponseError.message {
//                case "INVALID_EMAIL":
//                    return completeOnMain(nil, .invalidEmailError)
//                case "EMAIL_NOT_FOUND":
//                    return completeOnMain(nil, .emailNotFoundError)
//                case "INVALID_PASSWORD":
//                    return completeOnMain(nil, .correctEmailWrongPasswordError)
//                case "INVALID_LOGIN_CREDENTIALS":
//                    return completeOnMain(nil, .invalidLoginCredentialsError)
//                default:
//                    return completeOnMain(nil, .nonSuccessfulResponseCodeError(statusCode: httpResponse.statusCode))
//                }
//            } else {
//                return completeOnMain(nil, .unexpectedError)
//            }
//        }
//        task.resume()
//    }
//    
//    func loadCountries(loggedInUser: User, _ completionHandler: @escaping @Sendable ([Country]?, NetworkingError?) -> Void) {
//        
//        let completeOnMain: @Sendable ([Country]?, NetworkingError?) -> Void = { countryList, error in
//            DispatchQueue.main.async { completionHandler(countryList, error) }
//        }
//        
//        guard let loggedInUserIDToken = loggedInUser.idToken as String? else {
//            print("Missing ID Token")
//            return completionHandler(nil, .missingIDToken)
//        }
//        
//        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/mad-course-3ceb1/databases/(default)/documents/countries?pageSize=1000&orderBy=name") else {
//            print("Invalid URL")
//            return completeOnMain(nil, .unexpectedError)
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(loggedInUserIDToken)", forHTTPHeaderField: "Authorization")
//        
//        let task = session.dataTask(with: request) { data, response, error in
//           
//            if let error = error as NSError? {
//                print("URLSession Error: \(error.localizedDescription)")
//                if error.code == NSURLErrorNotConnectedToInternet, error.domain == NSURLErrorDomain {
//                    return completeOnMain(nil, .networkOfflineError)
//                } else {
//                    return completeOnMain(nil, .unexpectedError)
//                }
//            }
//            
//            // HTTPURLResponse provides methods for accessing information specific to HTTP protocol responses ... like .statusCode and .allHeaderFields
//            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
//                return completeOnMain(nil, .unexpectedResponseFormatError)
//            }
//            
//            print("Status: \(httpResponse.statusCode)")
//            print("Response: \(httpResponse.allHeaderFields) \n")
//            print("Data: \(String(data: data, encoding: .utf8) ?? "<non-utf8>")")
//            
//            if (200...299).contains(httpResponse.statusCode) {
//                do {
//                    let decoder = JSONDecoder()
//                    decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
//                    let container = try decoder.decode(DocumentsContainer.self, from: data)
//                    
//                    let countryList = container.documents
//                    print("Countries count: \(countryList.count)")
//                    print("First three elements in countryList:")
//                    for i in 0..<3 {
//                        print(countryList[i])
//                    }
//                    return completeOnMain(countryList, nil)
//                } catch {
//                    print("Response decoding error: \(error.localizedDescription)")
//                    return completeOnMain(nil, .unexpectedResponseFormatError)
//                }
//            }
//            
//            if let countriesResponseError = try? JSONDecoder().decode(CountriesErrorResponse.self, from: data) {
//                switch countriesResponseError.status {
//                case "PERMISSION_DENIED":
//                    return completeOnMain(nil, .permissionDeniedError)
//                default:
//                    return completeOnMain(nil, .nonSuccessfulResponseCodeError(statusCode: httpResponse.statusCode))
//                }
//            } else {
//                return completeOnMain(nil, .unexpectedError)
//            }
//            
//        }
//        task.resume()
//    }
//    
//}
//
