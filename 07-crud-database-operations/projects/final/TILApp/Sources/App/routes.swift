/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { _ in
        "It works!"
    }

    app.get("hello") { _ -> String in
        "Hello, world!"
    }

    app.post("api", "acronyms") { req async throws -> Acronym in
        let acronym = try req.content.decode(Acronym.self)
        try await acronym.save(on: req.db)
        return acronym
    }

    app.get("api", "acronyms") { req async throws -> [Acronym] in
        try await Acronym.query(on: req.db).all()
    }

    app.get("api", "acronyms", ":acronymID") { req async throws -> Acronym in
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return acronym
    }

    app.put("api", "acronyms", ":acronymID") { req async throws -> Acronym in
        let updatedAcronym = try req.content.decode(Acronym.self)
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        acronym.short = updatedAcronym.short
        acronym.long = updatedAcronym.long
        try await acronym.save(on: req.db)
        return acronym
    }

    app.delete("api", "acronyms", ":acronymID") { req async throws -> HTTPStatus in
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await acronym.delete(on: req.db)
        return .noContent
    }

    app.get("api", "acronyms", "search") { req async throws -> [Acronym] in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return try await Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
    }

    app.get("api", "acronyms", "first") { req async throws -> Acronym in
        guard let acronym = try await Acronym.query(on: req.db).first() else {
            throw Abort(.notFound)
        }
        return acronym
    }

    app.get("api", "acronyms", "sorted") { req async throws -> [Acronym] in
        try await Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
    }
}
