import Network
import Dependencies

public struct ReachabilityService {
	private let monitor: NWPathMonitor

	var status: NetworkStatus { monitor.status }
}

extension ReachabilityService {
	enum Error: Swift.Error {
		case noConnection
	}

	enum NetworkStatus: Equatable {
		case unknown
		case connected(interface: ConnectionType)
		case disconnected
	}

	enum ConnectionType {
		case wifi
		case cellular
		case ethernet
		case unknown
	}
}

// MARK: - Live
extension ReachabilityService {
	static let live = {
		let monitor = NWPathMonitor()
		let queue = DispatchQueue(label: "NWPathMonitor")
		monitor.start(queue: queue)
		return Self(monitor: monitor)
	}()
}

// MARK: - Helper

private extension NWPathMonitor {
	var status: ReachabilityService.NetworkStatus {
		switch currentPath.status {
		case .satisfied: .connected(interface: currentPath.connectionType)
		default: .disconnected
		}
	}
}

extension NWPath {
	var connectionType: ReachabilityService.ConnectionType {
		if usesInterfaceType(.wifi) {
			.wifi
		} else if usesInterfaceType(.cellular) {
			.cellular
		} else if usesInterfaceType(.wiredEthernet) {
			.ethernet
		} else {
			.unknown
		}
	}
}

// MARK: - Dependency
extension ReachabilityService: DependencyKey {
	public static var liveValue: Self = .live
}

extension DependencyValues {
	public var reachabilityService: ReachabilityService {
		get { self[ReachabilityService.self] }
		set { self[ReachabilityService.self] = newValue }
	}
}
