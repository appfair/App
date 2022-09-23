import AVKit

let allAVMetadataIdentifiers: [AVMetadataIdentifier] =  [
    AVMetadataIdentifier.commonIdentifierTitle,
    AVMetadataIdentifier.commonIdentifierCreator,
    AVMetadataIdentifier.commonIdentifierSubject,
    AVMetadataIdentifier.commonIdentifierDescription,
    AVMetadataIdentifier.commonIdentifierPublisher,
    AVMetadataIdentifier.commonIdentifierContributor,
    AVMetadataIdentifier.commonIdentifierCreationDate,
    AVMetadataIdentifier.commonIdentifierLastModifiedDate,
    AVMetadataIdentifier.commonIdentifierType,
    AVMetadataIdentifier.commonIdentifierFormat,
    AVMetadataIdentifier.commonIdentifierAssetIdentifier,
    AVMetadataIdentifier.commonIdentifierSource,
    AVMetadataIdentifier.commonIdentifierLanguage,
    AVMetadataIdentifier.commonIdentifierRelation,
    AVMetadataIdentifier.commonIdentifierLocation,
    AVMetadataIdentifier.commonIdentifierCopyrights,
    AVMetadataIdentifier.commonIdentifierAlbumName,
    AVMetadataIdentifier.commonIdentifierAuthor,
    AVMetadataIdentifier.commonIdentifierArtist,
    AVMetadataIdentifier.commonIdentifierArtwork,
    AVMetadataIdentifier.commonIdentifierMake,
    AVMetadataIdentifier.commonIdentifierModel,
    AVMetadataIdentifier.commonIdentifierSoftware,
    AVMetadataIdentifier.commonIdentifierAccessibilityDescription,
    AVMetadataIdentifier.quickTimeUserDataAlbum,
    AVMetadataIdentifier.quickTimeUserDataArranger,
    AVMetadataIdentifier.quickTimeUserDataArtist,
    AVMetadataIdentifier.quickTimeUserDataAuthor,
    AVMetadataIdentifier.quickTimeUserDataChapter,
    AVMetadataIdentifier.quickTimeUserDataComment,
    AVMetadataIdentifier.quickTimeUserDataComposer,
    AVMetadataIdentifier.quickTimeUserDataCopyright,
    AVMetadataIdentifier.quickTimeUserDataCreationDate,
    AVMetadataIdentifier.quickTimeUserDataDescription,
    AVMetadataIdentifier.quickTimeUserDataDirector,
    AVMetadataIdentifier.quickTimeUserDataDisclaimer,
    AVMetadataIdentifier.quickTimeUserDataEncodedBy,
    AVMetadataIdentifier.quickTimeUserDataFullName,
    AVMetadataIdentifier.quickTimeUserDataGenre,
    AVMetadataIdentifier.quickTimeUserDataHostComputer,
    AVMetadataIdentifier.quickTimeUserDataInformation,
    AVMetadataIdentifier.quickTimeUserDataKeywords,
    AVMetadataIdentifier.quickTimeUserDataMake,
    AVMetadataIdentifier.quickTimeUserDataModel,
    AVMetadataIdentifier.quickTimeUserDataOriginalArtist,
    AVMetadataIdentifier.quickTimeUserDataOriginalFormat,
    AVMetadataIdentifier.quickTimeUserDataOriginalSource,
    AVMetadataIdentifier.quickTimeUserDataPerformers,
    AVMetadataIdentifier.quickTimeUserDataProducer,
    AVMetadataIdentifier.quickTimeUserDataPublisher,
    AVMetadataIdentifier.quickTimeUserDataProduct,
    AVMetadataIdentifier.quickTimeUserDataSoftware,
    AVMetadataIdentifier.quickTimeUserDataSpecialPlaybackRequirements,
    AVMetadataIdentifier.quickTimeUserDataTrack,
    AVMetadataIdentifier.quickTimeUserDataWarning,
    AVMetadataIdentifier.quickTimeUserDataWriter,
    AVMetadataIdentifier.quickTimeUserDataURLLink,
    AVMetadataIdentifier.quickTimeUserDataLocationISO6709,
    AVMetadataIdentifier.quickTimeUserDataTrackName,
    AVMetadataIdentifier.quickTimeUserDataCredits,
    AVMetadataIdentifier.quickTimeUserDataPhonogramRights,
    AVMetadataIdentifier.quickTimeUserDataTaggedCharacteristic,
    AVMetadataIdentifier.quickTimeUserDataAccessibilityDescription,
    AVMetadataIdentifier.isoUserDataCopyright,
    AVMetadataIdentifier.isoUserDataDate,
    AVMetadataIdentifier.isoUserDataTaggedCharacteristic,
    AVMetadataIdentifier.isoUserDataAccessibilityDescription,
    AVMetadataIdentifier.identifier3GPUserDataCopyright,
    AVMetadataIdentifier.identifier3GPUserDataAuthor,
    AVMetadataIdentifier.identifier3GPUserDataPerformer,
    AVMetadataIdentifier.identifier3GPUserDataGenre,
    AVMetadataIdentifier.identifier3GPUserDataRecordingYear,
    AVMetadataIdentifier.identifier3GPUserDataLocation,
    AVMetadataIdentifier.identifier3GPUserDataTitle,
    AVMetadataIdentifier.identifier3GPUserDataDescription,
    AVMetadataIdentifier.identifier3GPUserDataCollection,
    AVMetadataIdentifier.identifier3GPUserDataUserRating,
    AVMetadataIdentifier.identifier3GPUserDataThumbnail,
    AVMetadataIdentifier.identifier3GPUserDataAlbumAndTrack,
    AVMetadataIdentifier.identifier3GPUserDataKeywordList,
    AVMetadataIdentifier.identifier3GPUserDataMediaClassification,
    AVMetadataIdentifier.identifier3GPUserDataMediaRating,
    AVMetadataIdentifier.quickTimeMetadataAuthor,
    AVMetadataIdentifier.quickTimeMetadataComment,
    AVMetadataIdentifier.quickTimeMetadataCopyright,
    AVMetadataIdentifier.quickTimeMetadataCreationDate,
    AVMetadataIdentifier.quickTimeMetadataDirector,
    AVMetadataIdentifier.quickTimeMetadataDisplayName,
    AVMetadataIdentifier.quickTimeMetadataInformation,
    AVMetadataIdentifier.quickTimeMetadataKeywords,
    AVMetadataIdentifier.quickTimeMetadataProducer,
    AVMetadataIdentifier.quickTimeMetadataPublisher,
    AVMetadataIdentifier.quickTimeMetadataAlbum,
    AVMetadataIdentifier.quickTimeMetadataArtist,
    AVMetadataIdentifier.quickTimeMetadataArtwork,
    AVMetadataIdentifier.quickTimeMetadataDescription,
    AVMetadataIdentifier.quickTimeMetadataSoftware,
    AVMetadataIdentifier.quickTimeMetadataYear,
    AVMetadataIdentifier.quickTimeMetadataGenre,
    AVMetadataIdentifier.quickTimeMetadataiXML,
    AVMetadataIdentifier.quickTimeMetadataLocationISO6709,
    AVMetadataIdentifier.quickTimeMetadataMake,
    AVMetadataIdentifier.quickTimeMetadataModel,
    AVMetadataIdentifier.quickTimeMetadataArranger,
    AVMetadataIdentifier.quickTimeMetadataEncodedBy,
    AVMetadataIdentifier.quickTimeMetadataOriginalArtist,
    AVMetadataIdentifier.quickTimeMetadataPerformer,
    AVMetadataIdentifier.quickTimeMetadataComposer,
    AVMetadataIdentifier.quickTimeMetadataCredits,
    AVMetadataIdentifier.quickTimeMetadataPhonogramRights,
    AVMetadataIdentifier.quickTimeMetadataCameraIdentifier,
    AVMetadataIdentifier.quickTimeMetadataCameraFrameReadoutTime,
    AVMetadataIdentifier.quickTimeMetadataTitle,
    AVMetadataIdentifier.quickTimeMetadataCollectionUser,
    AVMetadataIdentifier.quickTimeMetadataRatingUser,
    AVMetadataIdentifier.quickTimeMetadataLocationName,
    AVMetadataIdentifier.quickTimeMetadataLocationBody,
    AVMetadataIdentifier.quickTimeMetadataLocationNote,
    AVMetadataIdentifier.quickTimeMetadataLocationRole,
    AVMetadataIdentifier.quickTimeMetadataLocationDate,
    AVMetadataIdentifier.quickTimeMetadataDirectionFacing,
    AVMetadataIdentifier.quickTimeMetadataDirectionMotion,
    AVMetadataIdentifier.quickTimeMetadataPreferredAffineTransform,
    AVMetadataIdentifier.quickTimeMetadataDetectedFace,
    AVMetadataIdentifier.quickTimeMetadataDetectedHumanBody,
    AVMetadataIdentifier.quickTimeMetadataDetectedCatBody,
    AVMetadataIdentifier.quickTimeMetadataDetectedDogBody,
    AVMetadataIdentifier.quickTimeMetadataDetectedSalientObject,
    AVMetadataIdentifier.quickTimeMetadataVideoOrientation,
    AVMetadataIdentifier.quickTimeMetadataContentIdentifier,
    AVMetadataIdentifier.quickTimeMetadataAccessibilityDescription,
    AVMetadataIdentifier.quickTimeMetadataIsMontage,
    AVMetadataIdentifier.quickTimeMetadataAutoLivePhoto,
    AVMetadataIdentifier.quickTimeMetadataLivePhotoVitalityScore,
    AVMetadataIdentifier.quickTimeMetadataLivePhotoVitalityScoringVersion,
    AVMetadataIdentifier.quickTimeMetadataSpatialOverCaptureQualityScore,
    AVMetadataIdentifier.quickTimeMetadataSpatialOverCaptureQualityScoringVersion,
    AVMetadataIdentifier.quickTimeMetadataLocationHorizontalAccuracyInMeters,
    AVMetadataIdentifier.iTunesMetadataAlbum,
    AVMetadataIdentifier.iTunesMetadataArtist,
    AVMetadataIdentifier.iTunesMetadataUserComment,
    AVMetadataIdentifier.iTunesMetadataCoverArt,
    AVMetadataIdentifier.iTunesMetadataCopyright,
    AVMetadataIdentifier.iTunesMetadataReleaseDate,
    AVMetadataIdentifier.iTunesMetadataEncodedBy,
    AVMetadataIdentifier.iTunesMetadataPredefinedGenre,
    AVMetadataIdentifier.iTunesMetadataUserGenre,
    AVMetadataIdentifier.iTunesMetadataSongName,
    AVMetadataIdentifier.iTunesMetadataTrackSubTitle,
    AVMetadataIdentifier.iTunesMetadataEncodingTool,
    AVMetadataIdentifier.iTunesMetadataComposer,
    AVMetadataIdentifier.iTunesMetadataAlbumArtist,
    AVMetadataIdentifier.iTunesMetadataAccountKind,
    AVMetadataIdentifier.iTunesMetadataAppleID,
    AVMetadataIdentifier.iTunesMetadataArtistID,
    AVMetadataIdentifier.iTunesMetadataSongID,
    AVMetadataIdentifier.iTunesMetadataDiscCompilation,
    AVMetadataIdentifier.iTunesMetadataDiscNumber,
    AVMetadataIdentifier.iTunesMetadataGenreID,
    AVMetadataIdentifier.iTunesMetadataGrouping,
    AVMetadataIdentifier.iTunesMetadataPlaylistID,
    AVMetadataIdentifier.iTunesMetadataContentRating,
    AVMetadataIdentifier.iTunesMetadataBeatsPerMin,
    AVMetadataIdentifier.iTunesMetadataTrackNumber,
    AVMetadataIdentifier.iTunesMetadataArtDirector,
    AVMetadataIdentifier.iTunesMetadataArranger,
    AVMetadataIdentifier.iTunesMetadataAuthor,
    AVMetadataIdentifier.iTunesMetadataLyrics,
    AVMetadataIdentifier.iTunesMetadataAcknowledgement,
    AVMetadataIdentifier.iTunesMetadataConductor,
    AVMetadataIdentifier.iTunesMetadataDescription,
    AVMetadataIdentifier.iTunesMetadataDirector,
    AVMetadataIdentifier.iTunesMetadataEQ,
    AVMetadataIdentifier.iTunesMetadataLinerNotes,
    AVMetadataIdentifier.iTunesMetadataRecordCompany,
    AVMetadataIdentifier.iTunesMetadataOriginalArtist,
    AVMetadataIdentifier.iTunesMetadataPhonogramRights,
    AVMetadataIdentifier.iTunesMetadataProducer,
    AVMetadataIdentifier.iTunesMetadataPerformer,
    AVMetadataIdentifier.iTunesMetadataPublisher,
    AVMetadataIdentifier.iTunesMetadataSoundEngineer,
    AVMetadataIdentifier.iTunesMetadataSoloist,
    AVMetadataIdentifier.iTunesMetadataCredits,
    AVMetadataIdentifier.iTunesMetadataThanks,
    AVMetadataIdentifier.iTunesMetadataOnlineExtras,
    AVMetadataIdentifier.iTunesMetadataExecProducer,
    AVMetadataIdentifier.id3MetadataAudioEncryption, /* AENC Audio encryption */
    AVMetadataIdentifier.id3MetadataAttachedPicture, /* APIC Attached picture */
    AVMetadataIdentifier.id3MetadataAudioSeekPointIndex, /* ASPI Audio seek point index */
    AVMetadataIdentifier.id3MetadataComments, /* COMM Comments */
    AVMetadataIdentifier.id3MetadataCommercial, /* COMR Commercial frame */
    AVMetadataIdentifier.id3MetadataEncryption, /* ENCR Encryption method registration */
    AVMetadataIdentifier.id3MetadataEqualization, /* EQUA Equalization */
    AVMetadataIdentifier.id3MetadataEqualization2, /* EQU2 Equalisation (2) */
    AVMetadataIdentifier.id3MetadataEventTimingCodes, /* ETCO Event timing codes */
    AVMetadataIdentifier.id3MetadataGeneralEncapsulatedObject, /* GEOB General encapsulated object */
    AVMetadataIdentifier.id3MetadataGroupIdentifier, /* GRID Group identification registration */
    AVMetadataIdentifier.id3MetadataInvolvedPeopleList_v23, /* IPLS Involved people list */
    AVMetadataIdentifier.id3MetadataLink, /* LINK Linked information */
    AVMetadataIdentifier.id3MetadataMusicCDIdentifier, /* MCDI Music CD identifier */
    AVMetadataIdentifier.id3MetadataMPEGLocationLookupTable, /* MLLT MPEG location lookup table */
    AVMetadataIdentifier.id3MetadataOwnership, /* OWNE Ownership frame */
    AVMetadataIdentifier.id3MetadataPrivate, /* PRIV Private frame */
    AVMetadataIdentifier.id3MetadataPlayCounter, /* PCNT Play counter */
    AVMetadataIdentifier.id3MetadataPopularimeter, /* POPM Popularimeter */
    AVMetadataIdentifier.id3MetadataPositionSynchronization, /* POSS Position synchronisation frame */
    AVMetadataIdentifier.id3MetadataRecommendedBufferSize, /* RBUF Recommended buffer size */
    AVMetadataIdentifier.id3MetadataRelativeVolumeAdjustment, /* RVAD Relative volume adjustment */
    AVMetadataIdentifier.id3MetadataRelativeVolumeAdjustment2, /* RVA2 Relative volume adjustment (2) */
    AVMetadataIdentifier.id3MetadataReverb, /* RVRB Reverb */
    AVMetadataIdentifier.id3MetadataSeek, /* SEEK Seek frame */
    AVMetadataIdentifier.id3MetadataSignature, /* SIGN Signature frame */
    AVMetadataIdentifier.id3MetadataSynchronizedLyric, /* SYLT Synchronized lyric/text */
    AVMetadataIdentifier.id3MetadataSynchronizedTempoCodes, /* SYTC Synchronized tempo codes */
    AVMetadataIdentifier.id3MetadataAlbumTitle, /* TALB Album/Movie/Show title */
    AVMetadataIdentifier.id3MetadataBeatsPerMinute, /* TBPM BPM (beats per minute) */
    AVMetadataIdentifier.id3MetadataComposer, /* TCOM Composer */
    AVMetadataIdentifier.id3MetadataContentType, /* TCON Content type */
    AVMetadataIdentifier.id3MetadataCopyright, /* TCOP Copyright message */
    AVMetadataIdentifier.id3MetadataDate, /* TDAT Date */
    AVMetadataIdentifier.id3MetadataEncodingTime, /* TDEN Encoding time */
    AVMetadataIdentifier.id3MetadataPlaylistDelay, /* TDLY Playlist delay */
    AVMetadataIdentifier.id3MetadataOriginalReleaseTime, /* TDOR Original release time */
    AVMetadataIdentifier.id3MetadataRecordingTime, /* TDRC Recording time */
    AVMetadataIdentifier.id3MetadataReleaseTime, /* TDRL Release time */
    AVMetadataIdentifier.id3MetadataTaggingTime, /* TDTG Tagging time */
    AVMetadataIdentifier.id3MetadataEncodedBy, /* TENC Encoded by */
    AVMetadataIdentifier.id3MetadataLyricist, /* TEXT Lyricist/Text writer */
    AVMetadataIdentifier.id3MetadataFileType, /* TFLT File type */
    AVMetadataIdentifier.id3MetadataTime, /* TIME Time */
    AVMetadataIdentifier.id3MetadataInvolvedPeopleList_v24, /* TIPL Involved people list */
    AVMetadataIdentifier.id3MetadataContentGroupDescription, /* TIT1 Content group description */
    AVMetadataIdentifier.id3MetadataTitleDescription, /* TIT2 Title/songname/content description */
    AVMetadataIdentifier.id3MetadataSubTitle, /* TIT3 Subtitle/Description refinement */
    AVMetadataIdentifier.id3MetadataInitialKey, /* TKEY Initial key */
    AVMetadataIdentifier.id3MetadataLanguage, /* TLAN Language(s) */
    AVMetadataIdentifier.id3MetadataLength, /* TLEN Length */
    AVMetadataIdentifier.id3MetadataMusicianCreditsList, /* TMCL Musician credits list */
    AVMetadataIdentifier.id3MetadataMediaType, /* TMED Media type */
    AVMetadataIdentifier.id3MetadataMood, /* TMOO Mood */
    AVMetadataIdentifier.id3MetadataOriginalAlbumTitle, /* TOAL Original album/movie/show title */
    AVMetadataIdentifier.id3MetadataOriginalFilename, /* TOFN Original filename */
    AVMetadataIdentifier.id3MetadataOriginalLyricist, /* TOLY Original lyricist(s)/text writer(s) */
    AVMetadataIdentifier.id3MetadataOriginalArtist, /* TOPE Original artist(s)/performer(s) */
    AVMetadataIdentifier.id3MetadataOriginalReleaseYear, /* TORY Original release year */
    AVMetadataIdentifier.id3MetadataFileOwner, /* TOWN File owner/licensee */
    AVMetadataIdentifier.id3MetadataLeadPerformer, /* TPE1 Lead performer(s)/Soloist(s) */
    AVMetadataIdentifier.id3MetadataBand, /* TPE2 Band/orchestra/accompaniment */
    AVMetadataIdentifier.id3MetadataConductor, /* TPE3 Conductor/performer refinement */
    AVMetadataIdentifier.id3MetadataModifiedBy, /* TPE4 Interpreted, remixed, or otherwise modified by */
    AVMetadataIdentifier.id3MetadataPartOfASet, /* TPOS Part of a set */
    AVMetadataIdentifier.id3MetadataProducedNotice, /* TPRO Produced notice */
    AVMetadataIdentifier.id3MetadataPublisher, /* TPUB Publisher */
    AVMetadataIdentifier.id3MetadataTrackNumber, /* TRCK Track number/Position in set */
    AVMetadataIdentifier.id3MetadataRecordingDates, /* TRDA Recording dates */
    AVMetadataIdentifier.id3MetadataInternetRadioStationName, /* TRSN Internet radio station name */
    AVMetadataIdentifier.id3MetadataInternetRadioStationOwner, /* TRSO Internet radio station owner */
    AVMetadataIdentifier.id3MetadataSize, /* TSIZ Size */
    AVMetadataIdentifier.id3MetadataAlbumSortOrder, /* TSOA Album sort order */
    AVMetadataIdentifier.id3MetadataPerformerSortOrder, /* TSOP Performer sort order */
    AVMetadataIdentifier.id3MetadataTitleSortOrder, /* TSOT Title sort order */
    AVMetadataIdentifier.id3MetadataInternationalStandardRecordingCode, /* TSRC ISRC (international standard recording code) */
    AVMetadataIdentifier.id3MetadataEncodedWith, /* TSSE Software/Hardware and settings used for encoding */
    AVMetadataIdentifier.id3MetadataSetSubtitle, /* TSST Set subtitle */
    AVMetadataIdentifier.id3MetadataYear, /* TYER Year */
    AVMetadataIdentifier.id3MetadataUserText, /* TXXX User defined text information frame */
    AVMetadataIdentifier.id3MetadataUniqueFileIdentifier, /* UFID Unique file identifier */
    AVMetadataIdentifier.id3MetadataTermsOfUse, /* USER Terms of use */
    AVMetadataIdentifier.id3MetadataUnsynchronizedLyric, /* USLT Unsynchronized lyric/text transcription */
    AVMetadataIdentifier.id3MetadataCommercialInformation, /* WCOM Commercial information */
    AVMetadataIdentifier.id3MetadataCopyrightInformation, /* WCOP Copyright/Legal information */
    AVMetadataIdentifier.id3MetadataOfficialAudioFileWebpage, /* WOAF Official audio file webpage */
    AVMetadataIdentifier.id3MetadataOfficialArtistWebpage, /* WOAR Official artist/performer webpage */
    AVMetadataIdentifier.id3MetadataOfficialAudioSourceWebpage, /* WOAS Official audio source webpage */
    AVMetadataIdentifier.id3MetadataOfficialInternetRadioStationHomepage, /* WORS Official Internet radio station homepage */
    AVMetadataIdentifier.id3MetadataPayment, /* WPAY Payment */
    AVMetadataIdentifier.id3MetadataOfficialPublisherWebpage, /* WPUB Publishers official webpage */
    AVMetadataIdentifier.id3MetadataUserURL, /* WXXX User defined URL link frame */
    AVMetadataIdentifier.icyMetadataStreamTitle,
    AVMetadataIdentifier.icyMetadataStreamURL,
]

