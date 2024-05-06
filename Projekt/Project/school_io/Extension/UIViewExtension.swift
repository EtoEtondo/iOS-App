//
//  UIViewExtension.swift
//  school_io

import UIKit

extension UIView {
  @IBInspectable
  var cornerRadius: CGFloat {
    get {
      return layer.cornerRadius
    }
    
    set {
      layer.cornerRadius = newValue
    }
  }
}
