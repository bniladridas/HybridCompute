#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
#include <filesystem>
#include "utils.hpp"  // Helper functions

namespace fs = std::filesystem;

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "Usage: ./preprocess <input_folder> <output_folder>\n";
        return -1;
    }

    std::string input_folder = argv[1];
    std::string output_folder = argv[2];

    // Create output folder if it does not exist
    if (!fs::exists(output_folder)) {
        fs::create_directories(output_folder);
    }

    for (const auto& entry : fs::directory_iterator(input_folder)) {
        if (entry.is_regular_file()) {
            cv::Mat image = cv::imread(entry.path().string());
            if (image.empty()) {
                std::cerr << "Error loading image: " << entry.path() << "\n";
                continue;
            }

            int tile_size = 64;
            std::vector<cv::Mat> tiles = splitImageIntoTiles(image, tile_size);

            // Save tiles to output folder
            for (size_t i = 0; i < tiles.size(); ++i) {
                std::string path = output_folder + "/" + entry.path().stem().string() + "_tile_" + std::to_string(i) + ".jpg";
                if (!cv::imwrite(path, tiles[i])) {
                    std::cerr << "Error saving tile " << i << " to " << path << "\n";
                    return -1;
                }
            }

            std::cout << "Processed " << entry.path() << " and saved " << tiles.size() << " tiles!\n";
        }
    }

    return 0;
}