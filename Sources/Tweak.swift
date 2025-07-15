//
// Copyright (c) 2025 Nightwind
//

import UIKit
import CydiaSubstrate

@objc
private protocol PHRecentCallDetailsItemView {
	@objc var callUUID: String { get set }
	@objc var timeLabel: UILabel { get set }
	@objc var durationAndDataLabel: UILabel { get set }
}

@objc
private protocol CHRecentCall {
	@objc var callOccurrences: [[String: Any]] { get set }
}

@objc
private protocol PHRecentCallDetailsView {
	@objc var calendar: Calendar { get }
	@objc var timeFormatter: DateFormatter { get }
	@objc var summaries: NSArray { get set }
	@objc var recentCall: CHRecentCall { get set }

	@objc func didMoveToWindow() -> Void
}

private struct Hooks {
	static var origIMP: IMP?

	static func hook() {
		guard let targetClass = objc_getClass("PHRecentCallDetailsView") as? AnyClass else { return }

		typealias HookType = @convention(c) (PHRecentCallDetailsView, Selector) -> Void

		let hook: HookType = { target, selector in
			let orig = unsafeBitCast(Self.origIMP, to: HookType.self)
			orig(target, selector)

			for summary in target.summaries {
				guard let summaryView = summary as? UIView else { continue }

				guard summaryView.subviews.contains(where: { $0.tag == 100 }) == false else { return }

				let itemView = unsafeBitCast(summaryView, to: PHRecentCallDetailsItemView.self)

				guard let callOccurence = target.recentCall.callOccurrences.first(where: { element in
					(element["kCHCallOccurrenceUniqueIdKey"] as? String) == itemView.callUUID
				}) else { continue }

				guard let startDate = callOccurence["kCHCallOccurrenceDateKey"] as? Date else { continue }
				guard let duration = callOccurence["kCHCallOccurrenceDurationKey"] as? Double else { continue }

				if duration == 0 {
					continue
				}

				guard let endDate = target.calendar.date(byAdding: .second, value: Int(duration), to: startDate) else { continue }

				let endTimeLabel = UILabel()
				endTimeLabel.text = target.timeFormatter.string(from: endDate)
				endTimeLabel.font = itemView.timeLabel.font
				endTimeLabel.tag = 100
				endTimeLabel.translatesAutoresizingMaskIntoConstraints = false
				summaryView.addSubview(endTimeLabel)

				NSLayoutConstraint.activate([
					endTimeLabel.leadingAnchor.constraint(equalTo: itemView.timeLabel.leadingAnchor),
					endTimeLabel.bottomAnchor.constraint(equalTo: itemView.durationAndDataLabel.bottomAnchor)
				])
			}
		}

		MSHookMessageEx(targetClass, #selector(PHRecentCallDetailsView.didMoveToWindow), unsafeBitCast(hook, to: IMP.self), &origIMP)
	}
}

@_cdecl("swift_init")
func tweakInit() {
	Hooks.hook()
}