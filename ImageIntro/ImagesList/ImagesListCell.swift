//
//  ImagesListCell.swift
//  ImageIntro
//
//  Created by Никита Пономарев on 19.05.2025.
//
import UIKit

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet var dateLabel: UILabel!

}
