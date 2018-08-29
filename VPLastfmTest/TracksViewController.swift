//
//  ViewController.swift
//  VPLastfmTest
//
//  Created by Vitaly Plivachuk on 8/28/18.
//  Copyright © 2018 Vitaly Plivachuk. All rights reserved.
//

import UIKit
import VPLastfm


class TracksViewController: UIViewController {
    
    //MARK:- Const
    private let reuseIdentifier = "cell reuse identifier"
    
    //MARK:- Variables
    let tableView = UITableView()
    let tracksLimit: Int = 50
    var model: VPLastFMModel? = nil
    var items:[VPLastFMModel] = []{
        didSet{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        getData()
    }
    
    func setUpUI(){
        navigationItem.title = "Top Tags"
        self.view.addSubview(tableView)
        tableView.setAnchors()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func getData(){
        if let track = model as? VPLastFMTrack {
            getSimilarTracks(to: track)
        } else if let tag = model as? VPLastFMTag {
            getTopTracks(by: tag)
        } else {
            getTop()
        }
    }
    
    func getTopTracks(by tag:VPLastFMTag){
        navigationItem.title = tag.name
        tag.getTopTracks {[weak self] tracks,error  in
            if let error = error{
                self?.showMessage(error: error)
            }
            self?.items = tracks ?? []
        }
    }
    
    func getSimilarTracks(to track:VPLastFMTrack){
        navigationItem.title = track.name
        track.getSimilar(limit: tracksLimit) {[weak self] tracks,error in
            self?.items = tracks ?? []
        }
    }
    
    func getTop(){
        VPLastFMTag.getTopTags(completion: {[weak self] tags,error  in
            if let error = error{
                self?.showMessage(error: error)
            }
            self?.navigationItem.titleView?.layoutSubviews()
            self?.items = tags ?? []
        })
    }
}

extension TracksViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? items.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let newCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier){
            cell = newCell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        
        if let track = items[safe: indexPath.row] as? VPLastFMTrack{
            cell.textLabel?.text = track.name
            cell.detailTextLabel?.text = track.artist.name
        } else if let tag = items[safe: indexPath.row] as? VPLastFMTag{
            cell.textLabel?.text = tag.name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0, let model = items[safe: indexPath.row]{
            guard let tracksViewController = storyboard?.instantiateViewController(withIdentifier: TracksViewController.description()) as? TracksViewController else {return}
            tracksViewController.model = model
            self.navigationController?.pushViewController(tracksViewController, animated: true)
        }
    }
}

extension UIViewController{
    func showMessage(error:Error){
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
}

extension UIView{
    func setAnchors(in view:UIView? = nil, top:CGFloat = 0, bottom:CGFloat = 0, left:CGFloat = 0, right:CGFloat = 0){
        guard let superView = view ?? superview else {return}
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: superView.topAnchor, constant: top).isActive = true
        self.bottomAnchor.constraint(equalTo: superView.bottomAnchor, constant: bottom).isActive = true
        self.leftAnchor.constraint(equalTo: superView.leftAnchor, constant: left).isActive = true
        self.rightAnchor.constraint(equalTo: superView.rightAnchor, constant: right).isActive = true
    }
}

