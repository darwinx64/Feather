//
//  SourceAppViewController.swift
//  feather
//
//  Created by samara on 5/22/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import UIKit
import Nuke
import AlertKit
import CoreData

class SourceAppViewController: UITableViewController {
	var apps: [StoreAppsData] = []
	var oApps: [StoreAppsData] = []
	var filteredApps: [StoreAppsData] = []
	
	var name: String? { didSet { self.title = name } }
	private var selectedFilterOption: AppFilterOption = .default

	var uri: URL!
	
	var highlightAppName: String?
	var highlightBundleID: String?
	var highlightVersion: String?
	var highlightDeveloperName: String?
	var highlightDescription: String?
	
	private let sourceGET = SourceGET()
	
	public var searchController: UISearchController!
	
	private let activityIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .medium)
		indicator.hidesWhenStopped = true
		return indicator
	}()
	
	init() { super.init(style: .plain) }
	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupNavigation()
		setupSearchController()
		setupViews()
		loadAppsData()
	}
	
	fileprivate func setupViews() {
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.tableHeaderView = UIView()
		self.tableView.register(AppTableViewCell.self, forCellReuseIdentifier: "AppTableViewCell")
		self.navigationItem.titleView = activityIndicator
		self.activityIndicator.startAnimating()
	}
	
	private func updateFilterMenu() {
		let defaultAction = UIAction(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_BY_DEFAULT"), image: UIImage()) { [weak self] _ in
			self?.applyFilter(.default)
		}
		
		let nameAction = UIAction(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_BY_NAME"), image: UIImage(systemName: "textformat")) { [weak self] _ in
			self?.applyFilter(.name)
		}
		
		let dateAction = UIAction(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_BY_DATE"), image: UIImage(systemName: "calendar")) { [weak self] _ in
			self?.applyFilter(.date)
		}
		
		// Update actions with checkmarks
		defaultAction.state = selectedFilterOption == .default ? .on : .off
		nameAction.state = selectedFilterOption == .name ? .on : .off
		dateAction.state = selectedFilterOption == .date ? .on : .off
		
		let filterMenu = UIMenu(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_TITLE"), children: [defaultAction, nameAction, dateAction])
		let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease"), menu: filterMenu)
		
		self.navigationItem.rightBarButtonItem = filterButton
	}
	
	enum AppFilterOption {
		case `default`
		case name
		case date
	}
	
	func applyFilter(_ option: AppFilterOption) {
		selectedFilterOption = option
		
		switch option {
		case .default:
			apps = oApps
		case .name:
			apps = apps.sorted { $0.name < $1.name }
		case .date:
			apps = apps.sorted {
				guard let date0 = $0.versionDate else { return false }
				guard let date1 = $1.versionDate else { return true }
				return date0 < date1
			}
		}
		
		UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
			self.tableView.reloadData()
		}, completion: nil)
		
		updateFilterMenu()
	}
	
	fileprivate func setupNavigation() {
		self.navigationItem.largeTitleDisplayMode = .never
	}
	
	private func loadAppsData() {
		guard let uri = uri else { return }
		sourceGET.downloadURL(from: uri) { [weak self] result in
			switch result {
			case .success(let (data, _)):
				let parseResult = self?.sourceGET.parse(data: data)
				switch parseResult {
				case .success(let sourceData):
					DispatchQueue.main.async {
						
						self?.apps = sourceData.apps
						self?.oApps = sourceData.apps
						
						if let fil = self?.shouldFilter() {
							self?.apps = [fil].compactMap { $0 }
						}
						
						UIView.transition(with: self!.tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
							self!.activityIndicator.stopAnimating()
							self?.navigationItem.titleView = nil
							if (self?.highlightAppName == nil) {
								self?.updateFilterMenu()
							}
							self?.tableView.reloadData()
						}, completion: nil)
					}
				case .failure(let error):
					Debug.shared.log(message: "Error parsing data: \(error.localizedDescription)")
				case .none:
					break
				}
				
			case .failure(let error):
				Debug.shared.log(message: "Error fetching data: \(error.localizedDescription)")
			}
		}
	}
	
	private func shouldFilter() -> StoreAppsData? {
		guard
			let name = highlightAppName,
			let id = highlightBundleID,
			let version = highlightVersion,
			let desc = highlightDescription
		else {
			return nil
		}
		
		return filterApps(from: apps, name: name, id: id, version: version, desc: desc, devname: highlightDeveloperName).first
	}

	private func filterApps(from apps: [StoreAppsData], name: String, id: String, version: String, desc: String, devname: String?) -> [StoreAppsData] {
		return apps.filter { app in
			return app.name == name &&
				   app.bundleIdentifier == id &&
				   app.version == version &&
				   app.localizedDescription == desc &&
				   (devname == nil || app.developerName == devname)
		}
	}

}

extension SourceAppViewController {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return isFiltering ? filteredApps.count : apps.count
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let app = isFiltering ? filteredApps[indexPath.row] : apps[indexPath.row]
		if (app.screenshotURLs != nil), !app.screenshotURLs!.isEmpty, Preferences.appDescriptionAppearance != 2 {
			return 322
		} else if Preferences.appDescriptionAppearance == 2 {
			return UITableView.automaticDimension
		} else {
			return 72
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = AppTableViewCell(style: .subtitle, reuseIdentifier: "RoundedBackgroundCell")
		let app = isFiltering ? filteredApps[indexPath.row] : apps[indexPath.row]
		cell.configure(with: app)
		cell.selectionStyle = .none
		cell.backgroundColor = .clear
		cell.getButton.tag = indexPath.row
		cell.getButton.addTarget(self, action: #selector(getButtonTapped(_:)), for: .touchUpInside)
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(getButtonHold(_:)))
		cell.getButton.addGestureRecognizer(longPressGesture)
		cell.getButton.longPressGestureRecognizer = longPressGesture
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if isFiltering || apps.isEmpty || (highlightAppName != nil) {
			return nil
		} else {
			//return "\(apps.count) Apps"
			return String.localized(apps.count > 1 ? "SOURCES_APP_VIEW_CONTROLLER_NUMBER_OF_APPS_PLURAL" : "SOURCES_APP_VIEW_CONTROLLER_NUMBER_OF_APPS", arguments: "\(apps.count)")
		}
	}
}

extension SourceAppViewController: UISearchControllerDelegate, UISearchBarDelegate {
	func setupSearchController() {
		searchController = UISearchController(searchResultsController: nil)
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = true
		searchController.searchResultsUpdater = self
		searchController.delegate = self
		searchController.searchBar.placeholder = String.localized("SOURCES_APP_VIEW_CONTROLLER_SEARCH_APPS")
		if (highlightAppName == nil) {
			navigationItem.searchController = searchController
			definesPresentationContext = true
			navigationItem.hidesSearchBarWhenScrolling = true
		}
	}
	
	var isFiltering: Bool {
		return searchController.isActive && !searchBarIsEmpty
	}

	var searchBarIsEmpty: Bool {
		return searchController.searchBar.text?.isEmpty ?? true
	}
}

extension SourceAppViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		let searchText = searchController.searchBar.text ?? ""
		filterContentForSearchText(searchText)
		tableView.reloadData()
	}
	
	private func filterContentForSearchText(_ searchText: String) {
		let lowercasedSearchText = searchText.lowercased()

		filteredApps = apps.filter { app in
			let nameMatch = app.name.lowercased().contains(lowercasedSearchText)
			let bundleIdentifierMatch = app.bundleIdentifier.lowercased().contains(lowercasedSearchText) 
			let developerNameMatch = app.developerName?.lowercased().contains(lowercasedSearchText) ?? false
			let subtitleMatch = app.subtitle?.lowercased().contains(lowercasedSearchText) ?? false
			let localizedDescriptionMatch = app.localizedDescription?.lowercased().contains(lowercasedSearchText) ?? false

			return nameMatch || bundleIdentifierMatch || developerNameMatch || subtitleMatch || localizedDescriptionMatch
		}
	}

}
