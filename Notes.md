TODO:
	queue menu on playlists / albums / songs

MusicApplication.AlbumDetailViewController : MusicApplication.ContainerDetailViewController
MusicApplication.PlaylistDetailViewController : MusicApplication.ContainerDetailViewController

MusicApplication.SongsViewController : UICollectionViewController
	let requestController : RequestResponseController

RequestResponseController : MANGLED_SwiftObject
	request : ?
	currentResponseContext : ?
	inflightResponseContext : ?