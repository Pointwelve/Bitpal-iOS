swiftformat App/App --config ./.swiftformat --quiet
swiftformat App/AppTests --config ./.swiftformat --quiet
swiftformat App/Notification\ Service\ Extension --config ./.swiftformat --quiet
swiftformat App/Shared --config ./.swiftformat --quiet
swiftformat App/Widget --config ./.swiftformat --quiet
swiftformat Domain/Domain --config ./.swiftformat --quiet
swiftformat Domain/DomainTests --config ./.swiftformat --quiet
swiftformat Data/Data --config ./.swiftformat --quiet
swiftformat Data/DataTests --config ./.swiftformat --quiet
cd App && swiftlint autocorrect --quiet