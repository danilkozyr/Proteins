//
//  ProteinsVC.swift
//  proteins
//
//  Created by Daniil KOZYR on 8/3/19.
//  Copyright © 2019 Daniil KOZYR. All rights reserved.
//

import UIKit

// TODO: When loading the ligand you should display the spinning wheel of the activity monitor

class ProteinsVC: UIViewController {

    private var list: [String] = []
    private var filteredData: [String] = []
    private let fileReader = FileReader()
    private var downloader = RCSBDownloader()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(UINib(nibName: "LigandCell", bundle: nil), forCellReuseIdentifier: "ligandCell")
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 180.0
        }
    }
    
    @IBOutlet weak var indicatorBackground: RoundView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.hidesBackButton = true
        indicatorBackground.isHidden = true
        
        view.setGradientColor(colorOne: UIColor.Application.darkBlue,
                              colorTwo: UIColor.Application.lightBlue)
        
        
        list = fileReader.reader()
        filteredData = list
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        if list[0] == "Error" {
//            let alert = UIAlertController.ale
            navigationController?.popViewController(animated: true)
            return
        }
    }
        
}

extension ProteinsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        indicatorBackground.isHidden = false
        indicator.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true


        downloader.downloadConnections(for: filteredData[indexPath.row]) { [unowned self] (result) in
            switch result {
            case .success(let atoms, let connections):
                DispatchQueue.main.async {
                    let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "ProteinSceneVC") as! ProteinSceneVC
                    
                    nextVC.ligand = self.filteredData[indexPath.row]
                    nextVC.connections = connections
                    nextVC.atoms = atoms

                    self.indicatorBackground.isHidden = true
                    self.indicator.stopAnimating()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false

                    let backItem = UIBarButtonItem()
                    backItem.title = " "
                    self.navigationItem.backBarButtonItem = backItem

                    self.navigationController?.pushViewController(nextVC, animated: true)
                }
            case .error(let errorString):
                DispatchQueue.main.async {
                    tableView.deselectRow(at: indexPath, animated: true)
                    let alert = UIAlertController().createAlert(title: "Error", message: errorString, action: "Ok")
                    self.present(alert, animated: true)

                    UIApplication.shared.isNetworkActivityIndicatorVisible = false

                    self.indicatorBackground.isHidden = true
                    self.indicator.stopAnimating()
                }
                
                return
            }
        }
    }
    
}

extension ProteinsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ligandCell", for: indexPath) as! LigandCell
        let ligand = filteredData[indexPath.row]
        cell.ligandName.text = ligand
        cell.backgroundColor = .clear
        return cell
    }
    
    
}

extension ProteinsVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filteredData.removeAll()
        
        guard let searchText = searchController.searchBar.text else {
            return
        }
        if searchText.isEmpty {
            filteredData = list
            self.tableView.reloadData()
            return
        }

        for ligand in list {
            if ligand.containsIgnoringCase(find: searchText) {
                filteredData.append(ligand)
            }
        }
        
        self.tableView.reloadData()
    }
}

