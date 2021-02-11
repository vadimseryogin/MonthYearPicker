//
//  MonthYearPickerView.swift
//  MonthYearPicker
//
//  Copyright (c) 2016 Alexander Edge <alex@alexedge.co.uk>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

open class MonthYearPickerView: UIControl {

    /// specify min date. default is nil. When `minimumDate` > `maximumDate`, the values are ignored.
    /// If `date` is earlier than `minimumDate` when it is set, `date` is changed to `minimumDate`.
    open var minimumDate: Date? = nil {
        didSet {
            guard let minimumDate = minimumDate, calendar.compare(minimumDate, to: date, toGranularity: .month) == .orderedDescending else { return }
            date = minimumDate
        }
    }

    /// specify max date. default is nil. When `minimumDate` > `maximumDate`, the values are ignored.
    /// If `date` is later than `maximumDate` when it is set, `date` is changed to `maximumDate`.
    open var maximumDate: Date? = nil {
        didSet {
            guard let maximumDate = maximumDate, calendar.compare(date, to: maximumDate, toGranularity: .month) == .orderedDescending else { return }
            date = maximumDate
        }
    }

    /// default is current date when picker created
    open var date: Date = Date() {
        didSet {
            if let minimumDate = minimumDate, calendar.compare(minimumDate, to: date, toGranularity: .month) == .orderedDescending {
                date = calendar.date(from: calendar.dateComponents([.year, .month], from: minimumDate)) ?? minimumDate
            } else if let maximumDate = maximumDate, calendar.compare(date, to: maximumDate, toGranularity: .month) == .orderedDescending {
                date = calendar.date(from: calendar.dateComponents([.year, .month], from: maximumDate)) ?? maximumDate
            }
            setDate(date, animated: true)
            sendActions(for: .valueChanged)
            onChange?(date)
            onChangeRange?(date...endDate)
        }
    }

    /// default is current calendar when picker created
    open var calendar: Calendar = Calendar.autoupdatingCurrent {
        didSet {
            monthDateFormatter.calendar = calendar
            monthDateFormatter.timeZone = calendar.timeZone
            quarterDateFormatter.calendar = calendar
            quarterDateFormatter.timeZone = calendar.timeZone
            yearDateFormatter.calendar = calendar
            yearDateFormatter.timeZone = calendar.timeZone
        }
    }

    /// default is nil
    open var locale: Locale? {
        didSet {
            calendar.locale = locale
            monthDateFormatter.locale = locale
            yearDateFormatter.locale = locale
        }
    }

    open var mode: Mode = .monthAndYear {
        didSet {
            pickerView.reloadAllComponents()
            setDate(date, animated: false)
        }
    }

    lazy private var pickerView: UIPickerView = {
        let pickerView = UIPickerView(frame: self.bounds)
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return pickerView
    }()

    lazy private var monthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter
    }()

    lazy private var quarterDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("Q")
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()

    lazy private var yearDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("y")
        return formatter
    }()

    open var onChange: ((Date) -> Void)?

    open var onChangeRange: ((ClosedRange<Date>) -> Void)?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }

    private func initialSetup() {
        addSubview(pickerView)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        setDate(date, animated: false)
    }

    open override func layoutSubviews() {
        for view in subviews { view.frame = bounds }
    }

    /// if animated is YES, animate the wheels of time to display the new date
    /// http://www.openradar.me/35247464 .quarter bug still exists
    open func setDate(_ date: Date, animated: Bool) {
        guard let monthRange = calendar.maximumRange(of: .month),
              let quarterRange = calendar.maximumRange(of: .quarter),
              let yearRange = calendar.maximumRange(of: .year) else { return }
        let monthComponent = calendar.component(.month, from: date)
        let month = monthComponent - monthRange.lowerBound
        pickerView.selectRow(month, inComponent: .month, animated: animated, inMode: mode)
        let quarterComponent = (Double(monthComponent) / 3).rounded(.up)
        let quarter = Int(quarterComponent) - quarterRange.lowerBound
        pickerView.selectRow(quarter, inComponent: .quarter, animated: animated, inMode: mode)
        let year = calendar.component(.year, from: date) - yearRange.lowerBound
        pickerView.selectRow(year, inComponent: .year, animated: animated, inMode: mode)
        pickerView.reloadAllComponents()
    }

    internal func isValidDate(_ date: Date) -> Bool {
        if let minimumDate = minimumDate,
            let maximumDate = maximumDate, calendar.compare(minimumDate, to: maximumDate, toGranularity: .month) == .orderedDescending { return true }
        if let minimumDate = minimumDate, calendar.compare(minimumDate, to: date, toGranularity: .month) == .orderedDescending { return false }
        if let maximumDate = maximumDate, calendar.compare(date, to: maximumDate, toGranularity: .month) == .orderedDescending { return false }
        return true
    }
}

extension MonthYearPickerView: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
        if mode == .quaterAndYear {
            if let quarter = value(for: pickerView.selectedRow(inComponent: .quarter, inMode: mode), representing: .quarter) {
                dateComponents.month = 3 * (quarter - 1) + 1
            }
        } else {
            dateComponents.month = value(for: pickerView.selectedRow(inComponent: .month, inMode: mode), representing: .month)
        }
        dateComponents.year = value(for: pickerView.selectedRow(inComponent: .year, inMode: mode), representing: .year)
        guard let date = calendar.date(from: dateComponents) else { return }
        self.date = date
    }

}

extension MonthYearPickerView: UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch mode {
        case .monthAndYear:
            return 2
        case .quaterAndYear:
            return 2
        case .yearOnly:
            return 1
        }
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let component = Component(rawValue: component, mode) else { return 0 }
        switch component {
        case .month:
            return calendar.maximumRange(of: .month)?.count ?? 0
        case .quarter:
            return calendar.maximumRange(of: .quarter)?.count ?? 0
        case .year:
            return calendar.maximumRange(of: .year)?.count ?? 0
        }
    }

    private func value(for row: Int?, representing component: Calendar.Component) -> Int? {
        guard let range = calendar.maximumRange(of: component) else { return nil }
        guard let row = row else { return nil }
        return range.lowerBound + row
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel = view as? UILabel ?? {
            let label = UILabel()
            if #available(iOS 10.0, *) {
                label.font = .preferredFont(forTextStyle: .title2, compatibleWith: traitCollection)
                label.adjustsFontForContentSizeCategory = true
            } else {
                label.font = .preferredFont(forTextStyle: .title2)
            }
            label.textAlignment = .center
            return label
        }()

        guard let component = Component(rawValue: component, mode) else { return label }
        var dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)

        switch mode {
        case .monthAndYear:
            if component == .month {
                dateComponents.month = value(for: row, representing: .month)
                dateComponents.year = value(for: pickerView.selectedRow(inComponent: .year, inMode: mode), representing: .year)
            } else if component == .year {
                dateComponents.month = value(for: pickerView.selectedRow(inComponent: .month, inMode: mode), representing: .month)
                dateComponents.year = value(for: row, representing: .year)
            }
        case .quaterAndYear:
            if component == .quarter {
                dateComponents.quarter = value(for: row, representing: .quarter)
                dateComponents.year = value(for: pickerView.selectedRow(inComponent: .year, inMode: mode), representing: .year)
            } else if component == .year {
                dateComponents.quarter = value(for: pickerView.selectedRow(inComponent: .quarter, inMode: mode), representing: .quarter)
                dateComponents.year = value(for: row, representing: .year)
            }
        case .yearOnly:
            if component == .year {
                dateComponents.year = value(for: row, representing: .year)
            }
        }

        guard let date = calendar.date(from: dateComponents) else { return label }

        switch component {
            case .month:
                label.text = monthDateFormatter.string(from: date)
            case .year:
                label.text = yearDateFormatter.string(from: date)
            case .quarter:
                if let quarter = dateComponents.quarter {
                    label.text = "Q\(quarter)"
                }
        }

        if #available(iOS 13.0, *) {
            label.textColor = isValidDate(date) ? .label : .secondaryLabel
        } else {
            label.textColor = isValidDate(date) ? .black : .lightGray
        }

        return label
    }
}

fileprivate enum Component: Int {

    init?(rawValue: Int, _ mode: Mode) {
        switch (rawValue, mode) {
        case (0, .monthAndYear):
            self = .month
        case (0, .quaterAndYear):
            self = .quarter
        case (1, .monthAndYear), (1, .quaterAndYear), (0, .yearOnly):
            self = .year
        default:
            return nil
        }
    }

    case month
    case quarter
    case year

    func rawValue(_ mode: Mode) -> Int? {
        switch (self, mode) {
        case (.month, .monthAndYear), (.quarter, .quaterAndYear), (.year, .yearOnly):
            return 0
        case (.year, .monthAndYear), (.year, .quaterAndYear):
            return 1
        default:
            return nil
        }
    }
}

public enum Mode {
    case monthAndYear
    case quaterAndYear
    case yearOnly
}

private extension UIPickerView {
    func selectedRow(inComponent component: Component, inMode mode: Mode) -> Int? {
        guard let component = component.rawValue(mode) else { return nil }
        return selectedRow(inComponent: component)
    }

    func selectRow(_ row: Int, inComponent component: Component, animated: Bool, inMode mode: Mode) {
        guard let component = component.rawValue(mode) else { return }
        selectRow(row, inComponent: component, animated: animated)
    }
}

extension MonthYearPickerView {

    private var endDate: Date {
        switch mode {
        case .monthAndYear:
            return endOfMonth
        case .quaterAndYear:
            return endOfQuarter
        case .yearOnly:
            return endOfYear
        }
    }

    private var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, second: -1), to: date)!
    }

    private var endOfQuarter: Date {
        Calendar.current.date(byAdding: DateComponents(month: 3, second: -1), to: date)!
    }

    private var endOfYear: Date {
        Calendar.current.date(byAdding: DateComponents(year: 1, second: -1), to: date)!
    }

}

