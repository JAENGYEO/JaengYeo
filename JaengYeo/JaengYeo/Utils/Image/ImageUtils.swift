//
//  ImageUtils.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/16/26.
//

import Foundation
import UIKit

enum ImageUtils {
    static func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let fileName = UUID().uuidString + ".jpg"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        do {
            try data.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }
    
    static func loadImage(fileName: String?) -> UIImage? {
        guard let fileName else { return nil }

        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        return UIImage(contentsOfFile: url.path)
    }

}
