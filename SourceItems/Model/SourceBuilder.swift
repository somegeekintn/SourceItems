//
//  SourceBuilder.swift
//  SourceItems
//
//  Created by Casey Fleser on 6/17/22.
//

import Foundation

protocol SourceList {
    associatedtype Item    : SourceItem

    var items       : [Item] { get }
}

struct SourceRoot<Item: SourceItem> : SourceList {
    var items       : [Item]
    
    func filtered(matching term: String) -> Self {
        guard !term.isEmpty else { return self }
        var filteredRoot = self
        
        filteredRoot.items = items.compactMap { item in
            let filtered = item.filtered(matching: term)
            
            return filtered.match ? filtered.fItem : nil
        }

        return filteredRoot
    }
}

@resultBuilder
struct SourceBuilder {
    static func buildBlock<Item: SourceItem>(_ items: [Item]...) -> [Item] {
        Array(items.joined())
    }

    static func buildBlock<ItemA: SourceItem, ItemB>(_ itemA: [ItemA], _ itemB: [ItemB]) -> [ItemA] {
        []
    }

    static func buildExpression<Data: SourceItemData>(_ data: Data) -> [SourceItemVal<Data, Never>] {
        [SourceItemVal<Data, Never>(data: data)]
    }

    static func buildExpression<Item: SourceItem>(_ item: Item) -> [Item] {
        [item]
    }

    // (SourceItemData, [SourceItem]) from SourceItemData.with()
    static func buildExpression<Data: SourceItemData, Item: SourceItem>(_ pair: (data: Data, items: [Item])) -> [SourceItemVal<Data, Item>] {
        [SourceItemVal<Data, Item>(data: pair.data, children: pair.items)]
    }

    // [(SourceItemData, [SourceItem])] from single level of map onto SourceItemData.with()
    static func buildExpression<Data: SourceItemData, Item: SourceItem>(_ pairs: [(data: Data, items: [Item])]) -> [SourceItemVal<Data, Item>] {
        return pairs.map { (data, items) in
            SourceItemVal<Data, Item>(data: data, children: items)
        }
    }

    // Single SourceContainer
    static func buildExpression<Item: SourceItem>(_ container: SourceRoot<Item>) -> [Item] {
        container.items
    }

    static func buildArray<Item: SourceItem>(_ components: [[Item]]) -> [Item] {
        components.flatMap { $0 }
    }
    
    static func buildEither<Item: SourceItem>(first component: [Item]) -> [Item] {
        component
    }
    
    static func buildEither<Item: SourceItem>(second component: [Item]) -> [Item] {
        component
    }
    
    static func buildFinalResult<Item: SourceItem>(_ items: [Item]) -> SourceRoot<Item> {
        return SourceRoot<Item>(items: items)
    }
}

struct TestBuilder {
    init() {
        testBuild("Loop") {
            for x in 0...10 {
                x.with {
                    for y in 0...10 {
                        y
                    }
                }
            }
        }

        testBuild("Single Childless") {
            3
        }

        testBuild("Mixed Child Items") {
            // Currently matching buildBlock<ItemA, ItemB> and returning nothing
            // what we'd like to do is promote the first item to a kind with an
            // empty array of children. How to match and how to test since this
            // could be any number in any order? Furthermore, the return type
            // signature cannot be variable.
            
            // We could have something like withEmpty to indicate this item is capable
            // of having children, but does not currently have them.
            
            // Finally how will all of this work once filtering is added in? I guess
            // the type will not have to change and we can just empty the arrays as
            // needed and no disclosure would be shown
            3
            3.with {
                "foo"
            }
        }
    }
    
    func testBuild<Item: SourceItem>(_ msg: String, @SourceBuilder children: () -> SourceRoot<Item>) {
        print("\(msg): \(children().items)")
    }
}

