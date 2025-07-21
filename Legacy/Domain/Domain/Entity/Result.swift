//
//  Result.swift
//  Domain
//
//  Created by Ryne Cheow on 24/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//
import Foundation

public enum Progress {
   /// Attempting to load content
   case loading
   /// Part of the content has been returned, there is more available
   case partial
   /// All content has been returned, no more available
   case full

   // TODO: Deprecate once LoadState is removed
   public func toLoadState(paged: Bool) -> LoadState {
      switch self {
      case .partial: return paged ? .pageAvailable : .ready
      case .full: return .ready
      case .loading: return paged ? .pageLoading : .loading
      }
   }
}

public enum Content<T> {
   case with(T, Progress)
}

public enum Failure {
   /// Unable to complete due to internet connectivity
   case offline
   /// No content available
   case nothing
   /// Content available, but expired
   case expired
   /// Network, parsing, or miscellaneous error
   case error(Error)

   // TODO: Deprecate once LoadState is removed
   public func toLoadState(paged: Bool) -> LoadState {
      switch self {
      case .offline: return .offline
      case .error: return paged ? .pageError : .error
      case .expired: return paged ? .pageExpired : .expired
      case .nothing: return paged ? .pageEmpty : .empty
      }
   }
}

public indirect enum Result<T> {
   case failure(Failure)
   case content(Content<T>)
   case page(Result<T>)

   public var isDone: Bool {
      switch self {
      case let .content(.with(_, progress)):
         return progress == .full
      default:
         return false
      }
   }

   public var isLoading: Bool {
      switch self {
      case let .content(.with(_, progress)):
         return progress == .loading
      default:
         return false
      }
   }

   public var hasContent: Bool {
      switch self {
      case let .content(.with(_, progress)):
         return [.partial, .full].contains(progress)
      default:
         return false
      }
   }

   public var failed: Bool {
      switch self {
      case .failure:
         return true
      default:
         return false
      }
   }

   public var hasContentOrFailed: Bool {
      return hasContent || failed
   }

   /// Flatten page into top-level result.
   public var flattened: Result<T> {
      switch self {
      case let .page(page):
         return page
      default:
         return self
      }
   }

   public var isPaged: Bool {
      switch self {
      case .page: return true
      default: return false
      }
   }

   // TODO: Deprecate once LoadState is removed
   public func toLoadState() -> LoadState {
      switch flattened {
      case let .failure(failure):
         return failure.toLoadState(paged: isPaged)
      case let .content(.with(_, condition)):
         return condition.toLoadState(paged: isPaged)
      default:
         fatalError("Nesting pages is unsupported")
      }
   }

   public var contentValue: T? {
      switch self {
      case let .content(.with(value, _)):
         return value
      default:
         return nil
      }
   }

   internal var isOffline: Bool {
      switch self {
      case let .failure(.error(error)):
         return (error as NSError).isNetworkUnreachableError
      case .failure(.offline):
         return true
      default:
         return false
      }
   }

   public var isEmpty: Bool {
      switch self {
      case .failure(.nothing):
         return true
      default:
         return false
      }
   }
}
