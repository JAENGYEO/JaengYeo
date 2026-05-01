//
//  QuantityWidgetView.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import WidgetKit
import SwiftUI

struct QuantityWidgetView: View {
    let entry: QuantityWidgetEntry
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            headerView
            ForEach(entry.products, id: \.id) { product in
                productRow(product: product)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
        }
        .widgetURL(URL(string: "jaengyeo://widget-settings"))
    }
    
    private var headerView: some View {
        HStack {
            Text(entry.presetName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textColor)
            Spacer()
            Image("widgetLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 22)
        }
    }
    
    private func productRow(product: WidgetProductInfo) -> some View {
        HStack {
            Text(product.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textColor)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 8) {
                circleIcon(systemName: "minus")
                Text("\(product.quantity)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(textColor)
                    .frame(minWidth: 16)
                circleIcon(systemName: "plus")
            }
        }
    }
    
    private func circleIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(Color.accentColor)
            .clipShape(Circle())
    }
}
