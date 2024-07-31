import * as fs from "fs/promises";
import path from "path";
import { ConsoleAbbreviations, GameConsole } from "../sort/types";
import { LibretroConsoleNames } from "./types";

interface IGenreData {
  title: string;
  genre: string;
  crc: string;
}

export class LibretroService {
  private resolveGenreFileURL(gameConsole: GameConsole): string {
    const fileName = LibretroConsoleNames.get(gameConsole);
    const fileURL = `https://raw.githubusercontent.com/libretro/libretro-database/master/metadat/genre/${fileName}.dat`;
    return fileURL;
  }

  private resolveMetadataFilepath(gameConsole: GameConsole): string {
    const fileName = LibretroConsoleNames.get(gameConsole);
    const metadataDirectory = path.resolve(__dirname, "../../data/metadata");
    const filePath = `${metadataDirectory}/${fileName}.dat`;
    return filePath;
  }

  private resolveJSONFilepath(gameConsole: GameConsole): string {
    const fileName = ConsoleAbbreviations.get(gameConsole);
    const jsonDirectory = path.resolve(__dirname, "../../data/json");
    const filePath = `${jsonDirectory}/${fileName}.json`;
    return filePath;
  }

  private async downloadGenreFile(gameConsole: GameConsole): Promise<void> {
    const fileURL = this.resolveGenreFileURL(gameConsole);

    const fileResponse = await fetch(fileURL, { method: "GET" });
    if (!fileResponse.ok || !fileResponse.body) {
      console.log(LibretroConsoleNames.get(gameConsole));
      throw new Error(`File unable to be retrieved: ${fileResponse.statusText}`);
    }

    const metadataFilePath = await this.resolveMetadataFilepath(gameConsole);
    await fs.writeFile(metadataFilePath, fileResponse.body);
  }

  private async parseGenreFileToJSON(gameConsole: GameConsole): Promise<void> {
    const metadataFilePath = this.resolveMetadataFilepath(gameConsole);
    const metadata = await fs.readFile(metadataFilePath);
    const metadataString = metadata.toString();

    const parsedGenreData: IGenreData[] = [];

    const gameDataPattern = /game \([\s\S]+?\n\)/gim;
    const matches = [...metadataString.matchAll(gameDataPattern)];

    const matchingPattern =
      /comment \"(?<title>[\s\S]+?)\"\n\tgenre \"(?<genre>[\s\S]+?)\"\n\trom \( crc (?<crc>[\s\S]+?) \)/im;

    const dataByGenre = matches
      .map((match) => {
        const results = match[0].match(matchingPattern);

        return results?.groups as { title: string; genre: string; crc: string };
      })
      .reduce<{ [key: string]: { title: string; genre: string } }>(
        (accumulator, currentMatch) => {
          const temp = accumulator;
          const { crc, ...data } = currentMatch;
          temp[crc] = data;
          return temp;
        },
        {}
      );

    const jsonFilePath = this.resolveJSONFilepath(gameConsole);
    await fs.writeFile(jsonFilePath, JSON.stringify(dataByGenre, null, 2));
  }

  async updateGenreFileCache(): Promise<void> {
    const availableConsoles = Array.from(LibretroConsoleNames.keys());

    const downloadAllGenreFiles = await Promise.all(
      availableConsoles.map(this.downloadGenreFile.bind(this))
    );
    await downloadAllGenreFiles;

    const parseAllMetaData = await Promise.all(
      availableConsoles.map(this.parseGenreFileToJSON.bind(this))
    );
    await parseAllMetaData;
  }
}
