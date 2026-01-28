import SwiftUI

struct DashboardView: View {
    
    @State private var weight: Int = 88
    
    var body: some View {
        VStack {
           
//            ZStack(alignment: .top) {
                
               
                
                VStack {
                    
                    header
                    
                    currentWeight(88.6)
                    
//                    Spacer()
                }
                .padding(.horizontal, 24)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.theme.primary)
//                        .frame(height: 300)
                        .ignoresSafeArea()
                        .shadow(radius: 4)
                }

                
//            }
            
            CurrentWeightView(weight: 88.6)
            
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
    
    private var header: some View {
        HStack {
            Text(Date().formatted(date: .abbreviated, time: .omitted))
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.theme.accent)
            
            Spacer()
            
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.theme.accent)
        }
    }
    
    private func currentWeight(_ weight: Double) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            Text(weight, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.theme.background)

            Text("kg")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.theme.background)
        }
        .padding(24)
    }
    
}


#Preview {
    DashboardView()
}


struct CurrentWeightView: View {
    
    let weight: Double
    
    var body: some View {
//        ZStack {
            
//            VStack {
//                RoundedRectangle(cornerRadius: 8)
//                    .foregroundStyle(Color.theme.primary)
//                    .frame(width: 5, height: 100)
//                
//                Text(weight, format: .number.precision(.fractionLength(2)))
//
//            }
            
//            ForEach(1...20, id: \.self) { i in
//                
//                RoundedRectangle(cornerRadius: 8)
//                    .foregroundStyle(Color.theme.primary)
//                    .frame(width: 5, height: 20)
//                    .rotationEffect(.degrees(1 * Double(i)))
//                
//            }
//
        
        ArcTicksDemo()
        
        
            
            
//        }
            
    }
}


import SwiftUI

struct ArcTicksDemo: View {
    let minW = 60
    let maxW = 80
    
    let arcSpan: Double = 200
    let startAngle: Double = -100
    let radius: CGFloat = 250
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let count = maxW - minW + 1
            let step = arcSpan / Double(count - 1)

            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let angle = -35 + Double(i) * (70 / Double(count - 1))

                    Rectangle()
                        .frame(width: 2, height: 16)
                        .rotationEffect(.degrees(angle)) // 1) döndür
                        .offset(y: -radius)              // 2) dışarı it
                }
            }
            .frame(width: radius*2, height: radius*2)
            
//            ZStack {
//                // merkez referansı (opsiyon)
//                Circle().fill(.clear).frame(width: radius*2, height: radius*2)
//
//                ForEach(0..<count, id: \.self) { i in
//                    let angle = startAngle + Double(i) * step
//                    let value = minW + i
//                    let isMajor = value % 5 == 0
//                    
//                    VStack(spacing: 6) {
//                        // tick çizgisi
//                        Rectangle()
//                            .frame(width: isMajor ? 3 : 2,
//                                   height: isMajor ? 22 : 14)
//                            .cornerRadius(2)
//
//                        // major tick’lerde sayı
//                        if isMajor {
//                            Text("\(value)")
//                                .font(.caption2)
//                                .monospacedDigit()
//                        }
//                    }
//                    // 1) tick'i açıya göre döndür
//                    .rotationEffect(.degrees(angle))
//                    // 2) sonra dışarı taşı (yayın üzerine)
//                    .offset(x: 0, y: -radius)
//                    // 3) tüm grubu merkeze koy
//                    .position(center)
//                }
//            }
        }
        .frame(height: 320)
        .padding()
    }
}
